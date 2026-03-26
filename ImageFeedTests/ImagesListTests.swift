//
//  ImagesListTests.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed
import XCTest

// MARK: - Tests

final class ImagesListTests: XCTestCase {

    // MARK: - Properties

    private var presenter: ImagesListPresenterMock!
    private var viewController: ImagesListViewControllerMock!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        presenter = ImagesListPresenterMock()
        viewController = ImagesListViewControllerMock()
        viewController.presenter = presenter
        presenter.view = viewController
    }

    // MARK: - Tests

    func testViewControllerCallsPresenterViewDidLoad() {
        // Given
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as! ImagesListViewController
        let presenterMock = ImagesListPresenterMock()
        vc.presenter = presenterMock
        presenterMock.view = vc

        // When
        _ = vc.view

        // Then
        XCTAssertTrue(presenterMock.viewDidLoadCalled)
    }

    func testPresenterCallsFetchPhotosNextPage() {
        // When
        presenter.fetchPhotosNextPage()

        // Then
        XCTAssertTrue(presenter.fetchPhotosNextPageCalled)
    }

    func testPresenterCallsUpdateTableViewAnimated() {
        // When
        viewController.updateTableViewAnimated(from: 0, to: 5)

        // Then
        XCTAssertTrue(viewController.updateTableViewAnimatedCalled)
        XCTAssertEqual(viewController.receivedOldCount, 0)
        XCTAssertEqual(viewController.receivedNewCount, 5)
    }

    func testPresenterChangeLike() {
        // Given
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

        // When
        let expectation = expectation(description: "changeLike")
        presenter.changeLike(at: 0) { result in
            // Then
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
