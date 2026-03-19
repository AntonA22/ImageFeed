//
//  ProfileLogoutService.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 05.03.2026.
//

import Foundation
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()

    private let tokenStorage = OAuth2TokenStorage.shared
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    private let imagesListService = ImagesListService.shared

    private init() {}

    func logout(completion: (() -> Void)? = nil) {
        tokenStorage.clean()
        profileService.clean()
        profileImageService.clean()
        imagesListService.clean()
        cleanCookies(completion: completion)
    }

    private func cleanCookies(completion: (() -> Void)?) {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        let dataStore = WKWebsiteDataStore.default()
        let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, for: records) {
                completion?()
            }
        }
    }
}
