//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var colorPanel: UIView!
    @IBOutlet weak var deleteImageView: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        colorPanel.frame = self.bounds
        indicator.hidden = true
    }
    
}
