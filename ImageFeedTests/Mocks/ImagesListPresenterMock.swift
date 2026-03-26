//
//  ImagesListPresenterMock.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed

final class ImagesListPresenterMock: ImagesListPresenterProtocol {
    var viewDidLoadCalled = false
    var fetchPhotosNextPageCalled = false
    var changeLikeCalled = false
    var changeLikeIndex: Int?
    var view: ImagesListViewControllerProtocol?

    var photos: [Photo] = []

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }

    func changeLike(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        changeLikeCalled = true
        changeLikeIndex = index
        completion(.success(()))
    }
}
