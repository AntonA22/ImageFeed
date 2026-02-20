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
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let showTabBarControllerSegueIdentifier = "ShowTabBarController"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let token = storage.token, !token.isEmpty {
            fetchProfile(token: token)
        } else {
            showAuth()
        }
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
        // Закрываем экран авторизации
        vc.dismiss(animated: true) { [weak self] in
            guard let self else { return }

            // Забираем токен из хранилища
            guard let token = self.storage.token else { return }

            // И только потом грузим профиль (а переход — внутри success)
            self.fetchProfile(token: token)
        }
    }
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self = self else { return }

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
