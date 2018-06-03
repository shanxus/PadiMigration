//
//  EventMembersTVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class EventMembersTVC: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var membersCollectionView: UICollectionView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
