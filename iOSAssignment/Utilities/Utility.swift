//
//  Utility.swift
//  iOSAssignment
//
//  Created by Pratibha Bhandari on 4/20/18.
//  Copyright © 2018 Pratibha Bhandari. All rights reserved.
//

import UIKit
extension UIViewController {
    func showAlert(withTitle title: String, message: String, completion: (()->())? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Okay", style: .default) { (alert) in
            guard let completion = completion else {
                return
            }
            completion()
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}


