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
        let imageName = isLiked ? "like_on" : "like_off"
        likeButton.setImage(UIImage(named: imageName), for: .normal)
    }

    @objc
    @IBAction private func likeButtonClicked() {
        delegate?.imageListCellDidTapLike(self)
    }
}
