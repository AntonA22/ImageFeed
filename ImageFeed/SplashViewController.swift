//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 02.02.2026.
//

import UIKit

final class SplashViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private var isFetchingProfile = false
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let showTabBarControllerSegueIdentifier = "ShowTabBarController"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        fetchProfileIfNeeded()
    }
    
    private func showAuth() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        guard let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Не найден AuthViewController по Storyboard ID")
            return
        }

        authVC.delegate = self
        authVC.modalPresentationStyle = .fullScreen
        present(authVC, animated: true)
    }
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "splash_screen_logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#1A1B22")

        view.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        // Закрываем экран авторизации; профиль загрузится в viewDidAppear
        vc.dismiss(animated: true)
    }

    private func fetchProfileIfNeeded() {
        guard !isFetchingProfile else { return }

        guard let token = storage.token, !token.isEmpty else {
            showAuth()
            return
        }

        fetchProfile(token: token)
    }
    
    private func fetchProfile(token: String) {
        isFetchingProfile = true
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            guard let self else { return }
            self.isFetchingProfile = false
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success(let profile):
                 let username = profile.username

                 ProfileImageService.shared.fetchProfileImageURL(username: username) { _ in }

                self.switchToTabBarController()

            case .failure:
                // TODO [Sprint 11] Покажите ошибку получения профиля
                break
            }
        }
    }
    
    private func switchToTabBarController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController")

        guard
            let windowScene = view.window?.windowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
        else {
            assertionFailure("Cannot get window")
            return
        }

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}
