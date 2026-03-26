//
//  ProfileViewControllerMock.swift
//  ImageFeedTests
//
//  Created by Антон Абалуев on 20.03.2026.
//

@testable import ImageFeed

final class ProfileViewControllerMock: ProfileViewControllerProtocol {
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
