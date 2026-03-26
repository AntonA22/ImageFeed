//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 01.01.2026.
//

import UIKit
import Foundation
import Kingfisher

final class ImagesListCell: UITableViewCell {

    private enum Constants {
        static let likeOnImage = "like_on"
        static let likeOffImage = "like_off"
    }

    @IBOutlet  var dateLabel: UILabel!
    @IBOutlet  var likeButton: UIButton!
    @IBOutlet  var cellImageView: UIImageView!
    
    static let reuseIdentifier = "ImagesListCell"

    weak var delegate: ImagesListCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        likeButton.addTarget(self, action: #selector(likeButtonClicked), for: .touchUpInside)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImageView.kf.cancelDownloadTask()
        cellImageView.image = nil
    }
    
    func setIsLiked(_ isLiked: Bool) {
        let imageName = isLiked ? Constants.likeOnImage : Constants.likeOffImage
        likeButton.setImage(UIImage(named: imageName), for: .normal)
        likeButton.accessibilityIdentifier = isLiked ? "like button on" : "like button off"
    }

    @objc
    @IBAction private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
}
