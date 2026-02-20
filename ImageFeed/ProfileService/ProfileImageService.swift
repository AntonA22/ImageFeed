//
//  ProfileImageService.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 13.02.2026.
//
import Foundation

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String

    private enum CodingKeys: String, CodingKey {
        case small
        case medium
        case large
    }
}

struct UserResult: Codable {
    let profileImage: ProfileImage

    private enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

final class ProfileImageService {
    // Синглтон
    static let shared = ProfileImageService()
    private init() {}

    // Приватное свойство для хранения URL аватарки
    private(set) var avatarURL: String?

    private var task: URLSessionTask?
    
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    // Метод для получения аватарки по имени пользователя
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
            logError(
                "ProfileImageService.fetchProfileImageURL(username:)",
                "ProfileImageServiceError - missingToken, username=\(username)"
            )
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            logError(
                "ProfileImageService.fetchProfileImageURL(username:)",
                "ProfileImageServiceError - invalidRequest, username=\(username)"
            )
            completion(.failure(URLError(.badURL)))
            return
        }

        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self else { return }

            switch result {
            case .success(let userResult):
                let bestURL = userResult.profileImage.medium // лучше качество
                self.avatarURL = bestURL
                completion(.success(bestURL))
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": bestURL]
                )

            case .failure(let error):
                logError(
                    "ProfileImageService.fetchProfileImageURL(username:)",
                    "NetworkError - error=\(error.localizedDescription), username=\(username)"
                )
                completion(.failure(error))
            }
        }
        task?.resume()
    }

    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
