//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 16.01.2026.
//

import UIKit
import Kingfisher

final class ProfileViewController: UIViewController, ProfileViewControllerProtocol {

    var presenter: ProfilePresenterProtocol?

    private let profileLogoutService = ProfileLogoutService.shared

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(resource: .profile)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = .systemFont(ofSize: 23, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(hex: "#AEAFB4")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "Exit"), for: .normal)
        button.tintColor = .systemRed
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "logout button"
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#1A1B22")
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
        setupLayout()

        if presenter == nil {
            let presenter = ProfilePresenter()
            presenter.view = self
            self.presenter = presenter
        }

        presenter?.viewDidLoad()
    }

    // MARK: - ProfileViewControllerProtocol

    func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name
        usernameLabel.text = profile.loginName
        statusLabel.text = profile.bio
    }

    func updateAvatar(url: URL) {
        profileImageView.kf.setImage(
            with: url,
            placeholder: UIImage(resource: .profile)
        )
    }

    func showLogoutAlert() {
        let alert = UIAlertController(title: "Bye bye!", message: "Уверены, что хотите выйти?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
            self?.profileLogoutService.logout {
                self?.switchToSplashViewController()
            }
        })
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Private

    private func setupLayout() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(usernameLabel)
        view.addSubview(statusLabel)
        view.addSubview(logoutButton)

        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 32),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),

            usernameLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            statusLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),

            logoutButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            logoutButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 55),
            logoutButton.widthAnchor.constraint(equalToConstant: 24),
            logoutButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc
    private func didTapLogoutButton() {
        presenter?.didTapLogout()
    }

    private func switchToSplashViewController() {
        guard
            let windowScene = view.window?.windowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
        else {
            assertionFailure("Cannot get window")
            return
        }

        window.rootViewController = SplashViewController()
        window.makeKeyAndVisible()
    }
}


extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
