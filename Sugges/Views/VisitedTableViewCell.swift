//
//  VisitedTableViewCell.swift
//  Sugges
//
//  Created by Emre İÇMEN on 11.09.2024.
//

import UIKit

class VisitedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var placeKind: UILabel!
    @IBOutlet weak var placeDistrict: UILabel!
    @IBOutlet weak var placeRate: UILabel!
    @IBOutlet weak var placeAddedDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
