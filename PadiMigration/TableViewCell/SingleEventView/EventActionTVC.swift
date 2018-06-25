//
//  EventActionTVC.swift
//  PadiMigration
//
//  Created by Shan on 2018/6/24.
//  Copyright © 2018年 Shan. All rights reserved.
//

import UIKit

class EventActionTVC: UITableViewCell {
    @IBOutlet weak var statistics: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        statistics.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapStatistics(_:)))
        statistics.addGestureRecognizer(tap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func handleTapStatistics(_ sender: UIGestureRecognizer) {
        let topVC = GeneralService.findTopVC()
        if let showStatisticsVC = topVC.storyboard?.instantiateViewController(withIdentifier: "showStatisticsVC") as? ShowStatisticsVC {
            if let singleEventID = UserDefaults.standard.value(forKey: "rightNowSingleEventID") as? String {
                showStatisticsVC.singleEventID = singleEventID
                topVC.present(showStatisticsVC, animated: true, completion: nil)
            }
        }
    }

}
