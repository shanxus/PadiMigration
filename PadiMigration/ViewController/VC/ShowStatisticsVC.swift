//
//  ShowStatisticsVC.swift
//  PadiMigration
//
//  Created by Shan on 2018/6/25.
//  Copyright © 2018年 Shan. All rights reserved.
//

import UIKit
import Charts

class ShowStatisticsVC: UIViewController {
    @IBOutlet weak var navigationLabel: CustomView!
    @IBOutlet weak var navigationTitleLabel: UILabel!
    @IBOutlet weak var chartsSegment: UISegmentedControl!    
    @IBOutlet weak var chartViewBase: BarChartView!
    
    var singleEventID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let eventID = singleEventID {
            print("got event ID: ", eventID)
        }
        
    }

    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

}
