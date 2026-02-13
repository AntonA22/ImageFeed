//
//  SplashViewController.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 02.02.2026.
//

import UIKit

final class SplashViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage.shared
    
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let showTabBarControllerSegueIdentifier = "ShowTabBarController"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if storage.token != nil {
            performSegue(withIdentifier: showTabBarControllerSegueIdentifier, sender: nil)
        } else {
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }
}

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthenticationScreenSegueIdentifier {

            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)")
                return
            }

            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.navigationController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.performSegue(withIdentifier: self.showTabBarControllerSegueIdentifier, sender: nil)
        }
    }
}
