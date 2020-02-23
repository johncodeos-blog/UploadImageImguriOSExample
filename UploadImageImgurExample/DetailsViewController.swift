//
//  DetailsViewController.swift
//  UploadImageImgurExample
//
//  Created by John Codeos on 2/22/20.
//  Copyright © 2020 John Codeos. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {
    @IBOutlet var imgurURLTextView: UITextView!
    
    var imgurUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imgurURLTextView.text = imgurUrl
    }
}
