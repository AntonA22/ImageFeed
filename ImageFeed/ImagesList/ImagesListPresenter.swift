//
//  ImagesListPresenter.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 20.03.2026.
//

import Foundation

// MARK: - ImagesListPresenter

final class ImagesListPresenter: ImagesListPresenterProtocol {

    // MARK: - Properties

    weak var view: ImagesListViewControllerProtocol?

    private let imagesListService: ImagesListService

    var photos: [Photo] {
        imagesListService.photos
    }

    // MARK: - Init

    init(imagesListService: ImagesListService = .shared) {
        self.imagesListService = imagesListService
    }

    // MARK: - Public Methods

    func viewDidLoad() {
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let oldCount = (self.view as? ImagesListViewController)?.photosCount ?? 0
            let newCount = self.photos.count
            if oldCount != newCount {
                self.view?.updateTableViewAnimated(from: oldCount, to: newCount)
            }
        }

        imagesListService.fetchPhotosNextPage()
    }

    func fetchPhotosNextPage() {
        imagesListService.fetchPhotosNextPage()
    }

    func changeLike(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        let photo = photos[index]
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { result in
            completion(result)
        }
    }
}
