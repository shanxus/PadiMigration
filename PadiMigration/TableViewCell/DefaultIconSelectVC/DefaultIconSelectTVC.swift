//
//  DefaultIconSelectTVC.swift
//  PadiMigration
//
//  Created by Shan on 2018/6/4.
//  Copyright © 2018年 Shan. All rights reserved.
//

import UIKit

class DefaultIconSelectTVC: UITableViewCell {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var iconName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
