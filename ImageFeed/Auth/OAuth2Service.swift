//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 01.02.2026.
//

import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct OAuthTokenResponseBody: Decodable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

enum AuthServiceError: Error {
    case invalidRequest
    case requestInProgress
    case cancelled
    case noData
}
final class OAuth2Service {

    static let shared = OAuth2Service()

    private let tokenStorage = OAuth2TokenStorage.shared
    private let decoder = JSONDecoder()
    private let urlSession = URLSession.shared

    private var task: URLSessionTask?
    private var lastCode: String?

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        // 1) Если уже есть запрос с тем же code — второй не запускаем
        if task != nil, lastCode == code {
            logError(
                "OAuth2Service.fetchOAuthToken(_:)",
                "AuthServiceError - requestInProgress, code=\(code)"
            )
            completion(.failure(AuthServiceError.requestInProgress))
            return
        }

        // 2) Если есть запрос, но code другой — отменяем предыдущий
        if let currentTask = task, lastCode != code {
            currentTask.cancel()
        }

        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
            logError(
                "OAuth2Service.fetchOAuthToken(_:)",
                "AuthServiceError - invalidRequest, code=\(code)"
            )
            completion(.failure(AuthServiceError.invalidRequest))
            lastCode = nil
            task = nil
            return
        }

        task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self else { return }

            // Если за время запроса пришёл новый code — игнорим результат старого запроса
            guard self.lastCode == code else { return }

            self.task = nil
            self.lastCode = nil

            switch result {
            case .success(let body):
                let token = body.accessToken
                self.tokenStorage.token = token
                completion(.success(token))

            case .failure(let error):
                // Если запрос отменён — отдаём понятную ошибку
                if (error as NSError).code == NSURLErrorCancelled {
                    logError(
                        "OAuth2Service.fetchOAuthToken(_:)",
                        "AuthServiceError - cancelled, code=\(code)"
                    )
                    completion(.failure(AuthServiceError.cancelled))
                } else {
                    logError(
                        "OAuth2Service.fetchOAuthToken(_:)",
                        "NetworkError - error=\(error.localizedDescription), code=\(code)"
                    )
                    completion(.failure(error))
                }
            }
        }

        task?.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            assertionFailure("Failed to create URL")
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]

        guard let authTokenUrl = urlComponents.url else { return nil }

        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = HTTPMethod.post.rawValue // можно оставить "POST", но так аккуратнее
        return request
    }
}


import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}

    private enum Keys {
        static let token = "oauth_token"
    }

    var token: String? {
        get { KeychainWrapper.standard.string(forKey: Keys.token) }
        set {
            if let token = newValue {
                KeychainWrapper.standard.set(token, forKey: Keys.token)
            } else {
                KeychainWrapper.standard.removeObject(forKey: Keys.token)
            }
        }
    }

    func clean() {
        KeychainWrapper.standard.removeObject(forKey: Keys.token)
    }
}
