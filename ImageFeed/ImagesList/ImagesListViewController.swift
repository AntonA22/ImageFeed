//
//  ImagesListViewController.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 25.12.2025.
//

import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private let imagesListService = ImagesListService.shared
    private var photos: [Photo] = []
    private var likeInProgressPhotoIDs: Set<String> = []
    private let placeholderImage = UIImage(named: "Placeholder") ?? UIImage(systemName: "photo")

    @IBOutlet private var tableView: UITableView!
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveImagesListUpdate),
            name: ImagesListService.didChangeNotification,
            object: imagesListService
        )

        imagesListService.fetchPhotosNextPage()
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: ImagesListService.didChangeNotification,
            object: imagesListService
        )
    }

    @objc
    private func didReceiveImagesListUpdate() {
        updateTableViewAnimated()
    }

    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos

        guard oldCount != newCount else {
            return
        }

        tableView.performBatchUpdates {
            let indexPaths = (oldCount..<newCount).map { index in
                IndexPath(row: index, section: 0)
            }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    private func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось поставить лайк",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Ок", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

extension ImagesListViewController: UITableViewDataSource {
    
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        cell.cellImageView.kf.indicatorType = .activity

        if let imageURL = URL(string: photo.thumbImageURL) {
            cell.cellImageView.kf.setImage(
                with: imageURL,
                placeholder: placeholderImage
            ) { [weak self, weak cell] result in
                guard
                    let self,
                    let cell,
                    let visibleIndexPath = self.tableView.indexPath(for: cell)
                else {
                    return
                }

                switch result {
                case .success(let imageResult):
                    // Пересчитываем высоту только для реально загруженного из сети изображения.
                    guard imageResult.cacheType == .none else { return }
                    self.tableView.reloadRows(at: [visibleIndexPath], with: .automatic)
                case .failure:
                    break
                }
            }
        } else {
            cell.cellImageView.image = placeholderImage
        }

        if let createdAt = photo.createdAt {
            cell.dateLabel.text = dateFormatter.string(from: createdAt)
        } else {
            cell.dateLabel.text = ""
        }

        cell.setIsLiked(photo.isLiked)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }

        cell.delegate = self

        configCell(for: cell, with: indexPath)
        return cell
    }
}

extension ImagesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let imageSize = photos[indexPath.row].size
        guard imageSize.width > 0 else {
            return 0
        }
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = imageSize.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = imageSize.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }

            viewController.fullImageURL = URL(string: photos[indexPath.row].largeImageURL)
            if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
                viewController.image = cell.cellImageView.image
            }
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    func tableView(
      _ tableView: UITableView,
      willDisplay cell: UITableViewCell,
      forRowAt indexPath: IndexPath
    ) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
}


extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        guard !likeInProgressPhotoIDs.contains(photo.id) else { return }

        likeInProgressPhotoIDs.insert(photo.id)
        UIBlockingProgressHUD.show()

        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self else { return }
            self.likeInProgressPhotoIDs.remove(photo.id)
            UIBlockingProgressHUD.dismiss()

            switch result {
            case .success:
                self.photos = self.imagesListService.photos
                guard let updatedIndex = self.photos.firstIndex(where: { $0.id == photo.id }) else {
                    return
                }
                let updatedIndexPath = IndexPath(row: updatedIndex, section: 0)

                if let updatedCell = self.tableView.cellForRow(at: updatedIndexPath) as? ImagesListCell {
                    updatedCell.setIsLiked(self.photos[updatedIndex].isLiked)
                } else {
                    self.tableView.reloadRows(at: [updatedIndexPath], with: .none)
                }

            case .failure(let error):
                logError(
                    "ImagesListViewController.imageListCellDidTapLike(_:)",
                    "LikeFlowError - error=\(error.localizedDescription), photoId=\(photo.id)"
                )
                self.showLikeErrorAlert()
            }
        }
    }
}
