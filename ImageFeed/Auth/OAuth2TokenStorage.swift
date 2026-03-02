//
//  OAuth2TokenStorage.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 25.02.2026.
//

import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}

    private enum Keys {
        static let token = "oauth_token"
    }

    var token: String? {
        get { KeychainWrapper.standard.string(forKey: Keys.token) }
        set {
            if let token = newValue {
                KeychainWrapper.standard.set(token, forKey: Keys.token)
            } else {
                KeychainWrapper.standard.removeObject(forKey: Keys.token)
            }
        }
    }

    func clean() {
        KeychainWrapper.standard.removeObject(forKey: Keys.token)
    }
}
