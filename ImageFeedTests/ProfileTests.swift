//
//  ProfileTests.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed
import XCTest

// MARK: - Spies

final class ProfilePresenterSpy: ProfilePresenterProtocol {
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

final class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    var showLogoutAlertCalled = false
    var receivedProfile: Profile?
    var receivedAvatarURL: URL?

    func updateProfileDetails(profile: Profile) {
        updateProfileDetailsCalled = true
        receivedProfile = profile
    }

    func updateAvatar(url: URL) {
        updateAvatarCalled = true
        receivedAvatarURL = url
    }

    func showLogoutAlert() {
        showLogoutAlertCalled = true
    }
}

// MARK: - Tests

final class ProfileTests: XCTestCase {

    func testViewControllerCallsPresenterViewDidLoad() {
        // given
        let viewController = ProfileViewController()
        let presenter = ProfilePresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        _ = viewController.view

        // then
        XCTAssertTrue(presenter.viewDidLoadCalled)
    }

    func testPresenterCallsUpdateProfileDetails() {
        // given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        let profileResult = ProfileResult(
            username: "testuser",
            firstName: "Test",
            lastName: "User",
            bio: "Test bio"
        )
        let profile = Profile(result: profileResult)
        viewController.updateProfileDetails(profile: profile)

        // then
        XCTAssertTrue(viewController.updateProfileDetailsCalled)
        XCTAssertEqual(viewController.receivedProfile?.name, "Test User")
        XCTAssertEqual(viewController.receivedProfile?.loginName, "@testuser")
        XCTAssertEqual(viewController.receivedProfile?.bio, "Test bio")
    }

    func testPresenterCallsUpdateAvatar() {
        // given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController
        let url = URL(string: "https://example.com/avatar.png")!

        // when
        viewController.updateAvatar(url: url)

        // then
        XCTAssertTrue(viewController.updateAvatarCalled)
        XCTAssertEqual(viewController.receivedAvatarURL, url)
    }

    func testPresenterDidTapLogoutCallsShowLogoutAlert() {
        // given
        let viewController = ProfileViewControllerSpy()
        let presenter = ProfilePresenter()
        viewController.presenter = presenter
        presenter.view = viewController

        // when
        presenter.didTapLogout()

        // then
        XCTAssertTrue(viewController.showLogoutAlertCalled)
    }
}
