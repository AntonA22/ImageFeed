//
//  ImagesListTests.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed
import XCTest

// MARK: - Spies

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
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

final class ImagesListViewControllerSpy: ImagesListViewControllerProtocol {
    var presenter: ImagesListPresenterProtocol?
    var updateTableViewAnimatedCalled = false
    var showLikeErrorAlertCalled = false
    var receivedOldCount: Int?
    var receivedNewCount: Int?

    func updateTableViewAnimated(from oldCount: Int, to newCount: Int) {
        updateTableViewAnimatedCalled = true
        receivedOldCount = oldCount
        receivedNewCount = newCount
    }

    func showLikeErrorAlert() {
        showLikeErrorAlertCalled = true
    }
}

// MARK: - Tests

final class ImagesListTests: XCTestCase {

    func testViewControllerCallsPresenterViewDidLoad() {
        // given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as! ImagesListViewController
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        _ = viewController.view

        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    func testPresenterCallsFetchPhotosNextPage() {
        // given
        let presenter = ImagesListPresenterSpy()

        // when
        presenter.fetchPhotosNextPage()

        // then
        XCTAssertTrue(presenter.fetchPhotosNextPageCalled)
    }

    func testPresenterCallsUpdateTableViewAnimated() {
        // given
        let viewController = ImagesListViewControllerSpy()
        let presenter = ImagesListPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        viewController.updateTableViewAnimated(from: 0, to: 5)

        // then
        XCTAssertTrue(viewController.updateTableViewAnimatedCalled)
        XCTAssertEqual(viewController.receivedOldCount, 0)
        XCTAssertEqual(viewController.receivedNewCount, 5)
    }

    func testPresenterChangeLike() {
        // given
        let presenter = ImagesListPresenterSpy()
        presenter.photos = [
            Photo(
                id: "1",
                size: CGSize(width: 100, height: 100),
                createdAt: nil,
                welcomeDescription: nil,
                thumbImageURL: "https://example.com/thumb.jpg",
                largeImageURL: "https://example.com/large.jpg",
                isLiked: false
            )
        ]

        // when
        let expectation = expectation(description: "changeLike")
        presenter.changeLike(at: 0) { result in
            // then
            switch result {
            case .success:
                break
            case .failure:
                XCTFail("Expected success")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(presenter.changeLikeCalled)
        XCTAssertEqual(presenter.changeLikeIndex, 0)
    }
}
