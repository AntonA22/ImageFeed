//
//  ProfileTests.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed
import XCTest

// MARK: - Tests

final class ProfileTests: XCTestCase {

    func testViewControllerCallsPresenterViewDidLoad() {
        // Given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterMock()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        _ = viewController.view

        // Then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    func testPresenterCallsUpdateProfileDetails() {
        // Given
        let viewController = ProfileViewControllerMock()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        let profileResult = ProfileResult(
            username: "testuser",
            firstName: "Test",
            lastName: "User",
            bio: "Test bio"
        )
        let profile = Profile(result: profileResult)
        viewController.updateProfileDetails(profile: profile)

        // Then
        XCTAssertTrue(viewController.updateProfileDetailsCalled)
        XCTAssertEqual(viewController.receivedProfile?.name, "Test User")
        XCTAssertEqual(viewController.receivedProfile?.loginName, "@testuser")
        XCTAssertEqual(viewController.receivedProfile?.bio, "Test bio")
    }

    func testPresenterCallsUpdateAvatar() {
        // Given
        let viewController = ProfileViewControllerMock()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController
        let url = URL(string: "https://example.com/avatar.png")!

        // When
        viewController.updateAvatar(url: url)

        // Then
        XCTAssertTrue(viewController.updateAvatarCalled)
        XCTAssertEqual(viewController.receivedAvatarURL, url)
    }

    func testPresenterDidTapLogoutCallsShowLogoutAlert() {
        // Given
        let viewController = ProfileViewControllerMock()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController

        // When
        presenter.didTapLogout()

        // Then
        XCTAssertTrue(viewController.showLogoutAlertCalled)
    }
}
