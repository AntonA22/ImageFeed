//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 16.01.2026.
//

import UIKit
import Kingfisher
import WebKit

final class ProfileViewController: UIViewController {
    
    // Перегружаем конструктор
    override init(nibName: String?, bundle: Bundle?) {
         super.init(nibName: nibName, bundle: bundle)
         addObserver()
     }
    
    // Определяем конструктор, необходимый при декодировании
    // класса из Storyboard
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addObserver()
    }
    
    // Определяем деструктор
    deinit {
        removeObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(                 // 1
            self,                                               // 2
            selector: #selector(updateAvatar(notification:)),   // 3
            name: ProfileImageService.didChangeNotification,    // 4
            object: nil)                                        // 5
    }
    
    private func removeObserver() {
         NotificationCenter.default.removeObserver(              // 6
             self,                                               // 7
             name: ProfileImageService.didChangeNotification,    // 8
             object: nil)                                        // 9
     }
    
    @objc                                                       // 10
    private func updateAvatar(notification: Notification) {     // 11
        guard
            isViewLoaded,                                       // 12
            let userInfo = notification.userInfo,               // 13
            let profileImageURL = userInfo["URL"] as? String,   // 14
            let url = URL(string: profileImageURL)              // 15
        else { return }
        
        profileImageView.kf.setImage(
            with: url,
            placeholder: UIImage(resource: .profile)
        )
    }
    
    private let profileService = ProfileService.shared
    private let tokenStorage = OAuth2TokenStorage.shared

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
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#1A1B22")
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)

        guard let token = tokenStorage.token, !token.isEmpty else {
           print("Нет токена для загрузки профиля")
           return
        }
        
        if let avatarURL = ProfileImageService.shared.avatarURL,
           let url = URL(string: avatarURL) {

            profileImageView.kf.setImage(
                with: url,
                placeholder: UIImage(resource: .profile)
            )
        }
        
        updateProfileDetails()
        setupLayout()
    }

    private func updateProfileDetails() {
        guard let profile = profileService.profile else {
            return
        }

        nameLabel.text = profile.name
        usernameLabel.text = profile.loginName
        statusLabel.text = profile.bio
    }
    
    private func setupLayout() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(usernameLabel)
        view.addSubview(statusLabel)
        view.addSubview(logoutButton)

        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Profile image
            profileImageView.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: safe.topAnchor, constant: 32),
            profileImageView.widthAnchor.constraint(equalToConstant: 70),
            profileImageView.heightAnchor.constraint(equalToConstant: 70),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),

            // Username
            usernameLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),

            // Status
            statusLabel.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),

            // Logout button
            logoutButton.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            logoutButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: 55),
            logoutButton.widthAnchor.constraint(equalToConstant: 24),
            logoutButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    @objc
    private func didTapLogoutButton() {
        tokenStorage.clean()
        profileService.clean()
        ProfileImageService.shared.clean()
        clearWebViewData { [weak self] in
            self?.switchToSplashViewController()
        }
    }

    private func clearWebViewData(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records, completionHandler: completion)
        }
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
