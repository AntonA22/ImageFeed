//
//  ProfileService.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 09.02.2026.
//
import Foundation

struct ProfileResult: Codable {
    let username: String
    let firstName: String
    let lastName: String
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName  = "last_name"
        case bio
    }
}

enum ProfileServiceError: Error {
    case requestInProgress
    case invalidRequest
}

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?

    init(result: ProfileResult) {
        self.username = result.username
        self.name = "\(result.firstName) \(result.lastName)"
        self.loginName = "@\(result.username)"
        self.bio = result.bio
    }
}

final class ProfileService {
    
    static let shared = ProfileService()
    
    private(set) var profile: Profile?
    
    private var task: URLSessionTask?
    
    private init() {}
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        if task != nil {
            logError(
                "ProfileService.fetchProfile(_:)",
                "ProfileServiceError - requestInProgress, tokenIsEmpty=\(token.isEmpty)"
            )
            completion(.failure(ProfileServiceError.requestInProgress))
            return
        }

        guard let request = makeRequest(token: token) else {
            logError(
                "ProfileService.fetchProfile(_:)",
                "ProfileServiceError - invalidRequest, tokenIsEmpty=\(token.isEmpty)"
            )
            completion(.failure(ProfileServiceError.invalidRequest))
            return
        }
  
        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            guard let self else { return }
            self.task = nil

            switch result {
            case .success(let profileResult):
                let profile = Profile(result: profileResult)
                self.profile = profile
                completion(.success(profile))

            case .failure(let error):
                logError(
                    "ProfileService.fetchProfile(_:)",
                    "NetworkError - error=\(error.localizedDescription), tokenIsEmpty=\(token.isEmpty)"
                )
                completion(.failure(error))
            }
        }
        task?.resume()
    }
    
    private func makeRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            return nil
        }
        var request = URLRequest(url: url)
        
        guard !token.isEmpty else {
            return nil
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = HTTPMethod.get.rawValue

        return request
    }

    func clean() {
        task?.cancel()
        task = nil
        profile = nil
    }

}
