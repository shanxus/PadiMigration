//
//  ShowPayRelationTVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/8.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class ShowPayRelationTVC: UITableViewCell {
    @IBOutlet weak var leftSideImage: UIImageView!
    @IBOutlet weak var rightSideImage: UIImageView!

    @IBOutlet weak var leftSideName: UILabel!
    @IBOutlet weak var leftSideDescription: UILabel!
    @IBOutlet weak var rightSideDescription: UILabel!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
