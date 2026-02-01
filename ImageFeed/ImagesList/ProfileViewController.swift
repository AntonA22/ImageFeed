//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 16.01.2026.
//

import UIKit

final class ProfileViewController: UIViewController {

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "PfofileImage")
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

        setupLayout()
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
