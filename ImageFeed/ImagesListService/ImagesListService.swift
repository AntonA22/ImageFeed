//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 02.03.2026.
//

import UIKit
import Foundation

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

struct PhotoResult: Codable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let welcomeDescription: String?
    let likedByUser: Bool
    let urls: UrlsResult

    enum CodingKeys: String, CodingKey {
        case id
        case width
        case height
        case createdAt = "created_at"
        case welcomeDescription = "description"
        case likedByUser = "liked_by_user"
        case urls
    }
}

struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}


final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")

    private(set) var photos: [Photo] = []

    private var lastLoadedPage: Int?
    private var task: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage.shared
    private let dateFormatter = ISO8601DateFormatter()
    private let perPage = 10

    private init() {}

    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        guard task == nil else {
            return
        }

        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makePhotosRequest(page: nextPage) else {
            logError(
                "ImagesListService.fetchPhotosNextPage()",
                "Failed to create request for page=\(nextPage)"
            )
            return
        }

        task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            self.task = nil

            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.map(self.makePhoto(from:))
                DispatchQueue.main.async {
                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                }
            case .failure(let error):
                logError(
                    "ImagesListService.fetchPhotosNextPage()",
                    "NetworkError - error=\(error.localizedDescription), page=\(nextPage)"
                )
            }
        }

        task?.resume()
    }

    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard let token = tokenStorage.token, !token.isEmpty else {
            return nil
        }

        guard var components = URLComponents(string: "\(Constants.defaultBaseURLString)/photos") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func makePhoto(from result: PhotoResult) -> Photo {
        let createdAt = result.createdAt.flatMap { dateFormatter.date(from: $0) }

        return Photo(
            id: result.id,
            size: CGSize(width: result.width, height: result.height),
            createdAt: createdAt,
            welcomeDescription: result.welcomeDescription,
            thumbImageURL: result.urls.thumb,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser
        )
    }

    func clean() {
        task?.cancel()
        task = nil
        photos = []
        lastLoadedPage = nil
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)

        guard let token = tokenStorage.token, !token.isEmpty else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        guard let url = URL(string: "\(Constants.defaultBaseURLString)/photos/\(photoId)/like") else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? HTTPMethod.post.rawValue : HTTPMethod.delete.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        let photo = self.photos[index]
                        let newPhoto = Photo(
                            id: photo.id,
                            size: photo.size,
                            createdAt: photo.createdAt,
                            welcomeDescription: photo.welcomeDescription,
                            thumbImageURL: photo.thumbImageURL,
                            largeImageURL: photo.largeImageURL,
                            isLiked: !photo.isLiked
                        )
                        self.photos[index] = newPhoto
                    }
                    completion(.success(()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
