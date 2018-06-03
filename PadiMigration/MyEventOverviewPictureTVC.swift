//
//  MyEventOverviewPictureTVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/6.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class MyEventOverviewPictureTVC: UITableViewCell {

    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
