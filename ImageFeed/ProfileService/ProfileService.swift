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
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        guard let request = makeRequest(token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }
            
            do {
                let result = try JSONDecoder().decode(ProfileResult.self, from: data)
                let profile = Profile(result: result)
                
                DispatchQueue.main.async {
                    completion(.success(profile))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
            
    }
    
}
