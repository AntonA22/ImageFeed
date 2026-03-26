//
//  ProfilePresenterMock.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed

final class ProfilePresenterMock: ProfilePresenterProtocol {
    var viewDidLoadCalled = false
    var didTapLogoutCalled = false
    var view: ProfileViewControllerProtocol?

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func didTapLogout() {
        didTapLogoutCalled = true
    }
}
