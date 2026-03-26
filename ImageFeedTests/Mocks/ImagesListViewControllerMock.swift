//
//  ImagesListViewControllerMock.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed

final class ImagesListViewControllerMock: ImagesListViewControllerProtocol {
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
