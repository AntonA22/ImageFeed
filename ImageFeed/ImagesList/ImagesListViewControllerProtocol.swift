//
//  ImagesListViewControllerProtocol.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 20.03.2026.
//

import Foundation

protocol ImagesListViewControllerProtocol: AnyObject {
    var presenter: ImagesListPresenterProtocol? { get set }
    func updateTableViewAnimated(from oldCount: Int, to newCount: Int)
    func showLikeErrorAlert()
}
