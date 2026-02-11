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
    
    private var task: URLSessionDataTask?
    private var lastCode: String?
    
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        if let currentTask = task, lastCode == code {
            completion(.failure(AuthServiceError.requestInProgress))
            return
        }

        if let currentTask = task, lastCode != code {
            currentTask.cancel()
        }
        lastCode = code

        guard let request = makeOAuthTokenRequest(code: code) else {
           completion(.failure(AuthServiceError.invalidRequest))      // ✅ (c)
           lastCode = nil
           return
        }
        var newTask: URLSessionDataTask?
        newTask = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                
                guard self.task === newTask else { return }
                
                self.task = nil
                self.lastCode = nil
                
                // Обработка отмены
                if let error = error as? URLError, error.code == .cancelled {
                    completion(.failure(AuthServiceError.cancelled))
                    return
                }
                
                // Ошибка сети
                if let error {
                    completion(.failure(error))
                    return
                }
                
                // Нет данных
                guard let data else {
                    completion(.failure(AuthServiceError.noData))
                    return
                }
                
                // Декодим токен
                do {
                    let body = try self.decoder.decode(OAuthTokenResponseBody.self, from: data)
                    let token = body.accessToken
                    self.tokenStorage.token = token
                    completion(.success(token))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task = newTask
        newTask?.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {  // 18
        guard
            var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token")
        else {
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
        
        guard let authTokenUrl = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        return request
    }
}


final class OAuth2TokenStorage {
    private let tokenKey = "oauth_token"
    
    static let shared = OAuth2TokenStorage()

    var token: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
}
