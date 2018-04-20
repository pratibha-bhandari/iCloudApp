//
//  Alert.swift
//  iOSAssignment
//
//  Created by Pratibha Bhandari on 4/20/18.
//  Copyright © 2018 Pratibha Bhandari. All rights reserved.
//

import Foundation
import UIKit

class Alert {
    class func showBasicAlert(title:String, message: String, vc: ViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true)
    }
}
