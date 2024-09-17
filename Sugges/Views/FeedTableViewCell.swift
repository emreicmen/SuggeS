//
//  FeedTableViewCell.swift
//  Sugges
//
//  Created by Emre İÇMEN on 29.08.2024.
//

import UIKit

class FeedTableViewCell: UITableViewCell {

    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var placeKind: UILabel!
    @IBOutlet weak var placeRate: UILabel!
    @IBOutlet weak var placeAddedDate: UILabel!
    @IBOutlet weak var placeDistrict: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
