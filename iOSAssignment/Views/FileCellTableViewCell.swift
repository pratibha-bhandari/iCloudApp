//
//  FileCellTableViewCell.swift
//  iOSAssignment
//
//  Created by Pratibha Bhandari on 20/04/18.
//  Copyright © 2018 Pratibha Bhandari. All rights reserved.
//

import UIKit

class FileCellTableViewCell: UITableViewCell {

    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
