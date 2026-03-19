//
//  Photo.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 02.03.2026.
//

import UIKit

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}
