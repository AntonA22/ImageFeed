//
//  ProfilePresenter.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 20.03.2026.
//

import Foundation

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func didTapLogout()
}

protocol ProfileViewControllerProtocol: AnyObject {
    var presenter: ProfilePresenterProtocol? { get set }
    func updateProfileDetails(profile: Profile)
    func updateAvatar(url: URL)
    func showLogoutAlert()
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?

    private let profileService: ProfileService
    private let profileImageService: ProfileImageService

    init(
        profileService: ProfileService = .shared,
        profileImageService: ProfileImageService = .shared
    ) {
        self.profileService = profileService
        self.profileImageService = profileImageService
    }

    func viewDidLoad() {
        if let profile = profileService.profile {
            view?.updateProfileDetails(profile: profile)
        }

        if let avatarURL = profileImageService.avatarURL,
           let url = URL(string: avatarURL) {
            view?.updateAvatar(url: url)
        }

        NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let userInfo = notification.userInfo,
                let profileImageURL = userInfo["URL"] as? String,
                let url = URL(string: profileImageURL)
            else { return }

            self?.view?.updateAvatar(url: url)
        }
    }

    func didTapLogout() {
        view?.showLogoutAlert()
    }
}
