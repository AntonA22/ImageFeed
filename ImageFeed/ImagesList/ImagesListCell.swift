//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Антон Абалуев on 01.01.2026.
//

import UIKit
import Foundation

final class ImagesListCell: UITableViewCell {
    
    @IBOutlet  var dateLabel: UILabel!
    @IBOutlet  var likeButton: UIButton!
    @IBOutlet  var cellImageView: UIImageView!
    
    static let reuseIdentifier = "ImagesListCell"
    
}
