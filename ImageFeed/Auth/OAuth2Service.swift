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

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}

    private let tokenStorage = OAuth2TokenStorage()
    
    private let decoder = JSONDecoder()

    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                do {
                    let response = try self.decoder.decode(OAuthTokenResponseBody.self, from: data)
                    self.tokenStorage.token = response.accessToken
                    completion(.success(response.accessToken))
                } catch {
                    print("Decoding error:", error)
                    completion(.failure(NetworkError.decodingError(error)))
                }

            case .failure(let error):
                print("Network error:", error)
                completion(.failure(error))
            }
        }

        task.resume()
    }
    
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var components = URLComponents(string: "https://unsplash.com/oauth/token") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
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
