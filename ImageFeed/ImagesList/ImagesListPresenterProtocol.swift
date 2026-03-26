//
//  ImagesListPresenterProtocol.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 20.03.2026.
//

import Foundation

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewControllerProtocol? { get set }
    var photos: [Photo] { get }
    func viewDidLoad()
    func fetchPhotosNextPage()
    func changeLike(at index: Int, completion: @escaping (Result<Void, Error>) -> Void)
}
