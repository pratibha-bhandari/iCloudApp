//
//  ExtensionTableViewCell.swift
//  iOSAssignment
//
//  Created by Pratibha Bhandari on 20/04/18.
//  Copyright © 2018 Pratibha Bhandari. All rights reserved.
//

import UIKit

class ExtensionTableViewCell: UITableViewCell {

    @IBOutlet weak var extensionLabel: UILabel!
    @IBOutlet weak var frequencyLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
