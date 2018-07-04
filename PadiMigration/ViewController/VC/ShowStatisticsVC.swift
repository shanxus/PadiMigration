//
//  ShowStatisticsVC.swift
//  PadiMigration
//
//  Created by Shan on 2018/6/25.
//  Copyright © 2018年 Shan. All rights reserved.
//

import UIKit
import Charts
import Firebase
import SwiftyJSON

class ShowStatisticsVC: UIViewController {
    @IBOutlet weak var navigationLabel: CustomView!
    @IBOutlet weak var navigationTitleLabel: UILabel!
    @IBOutlet weak var chartsSegment: UISegmentedControl!    
    @IBOutlet weak var barChartViewBG: BarChartView!
    
    var pieChartViewBG: PieChartView!
    
    var paysID: [String] = []
    var paysValue: [String: Float] = [:]
    
    var barChartDataset: [BarChartDataEntry] = []
    var pieChartDataset: [PieChartDataEntry] = []
    
    var singleEventID: String?
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let eventID = singleEventID {
            print("got event ID: ", eventID)
        }
        chartsSegment.selectedSegmentIndex = 0
        barChartViewBG.backgroundColor = .black
        loadEventData()
        
        setPieChart()
    }
    
    @IBAction func segmentTapped(_ sender: Any) {
        if let segment = sender as? UISegmentedControl {
            if segment.selectedSegmentIndex == 0 {
                buildBarChart()
            } else {
                buildPieChart()
            }
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setPieChart() {
        pieChartViewBG = PieChartView()
        pieChartViewBG.backgroundColor = .black
        
        view.addSubview(pieChartViewBG)
        pieChartViewBG.leadingAnchor.constraint(equalTo: barChartViewBG.leadingAnchor, constant: 0).isActive = true
        pieChartViewBG.trailingAnchor.constraint(equalTo: barChartViewBG.trailingAnchor, constant: 0).isActive = true
        pieChartViewBG.bottomAnchor.constraint(equalTo: barChartViewBG.bottomAnchor, constant: 0).isActive = true
        pieChartViewBG.topAnchor.constraint(equalTo: barChartViewBG.topAnchor, constant: 0).isActive = true
        pieChartViewBG.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func loadEventData() {
        guard let eventID = singleEventID else {return}
        
        /* fetch creator ID. */
        let creatorRef = ref.child(DBPathStrings.eventCreator).child(eventID)
        creatorRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (creator, _) in json.dictionaryValue {
                let creatorID = creator
                
                /* fetch pays ID. */
                let eventRef = self.ref.child(DBPathStrings.eventDataPath).child(creatorID).child(eventID).child(DBPathStrings.paysPath)
                eventRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    let json = JSON(snapshot.value ?? "")
                    
                    let dispatch = DispatchGroup()
                    
                    for (_, payID) in json.dictionaryValue {
                        self.paysValue[payID.stringValue] = 0
                        self.paysID.append(payID.stringValue)
                        
                        let sharedPayValueRef = self.ref.child(DBPathStrings.payDataPath).child(creatorID).child(payID.stringValue).child(DBPathStrings.payerPath)
                        dispatch.enter()
                        sharedPayValueRef.observeSingleEvent(of: .value, with: { (snapshot) in
                            let json = JSON(snapshot.value ?? "")
                            for (_, info) in json.dictionaryValue {
                                if let value = info[DBPathStrings.value].float {
                                    self.paysValue[payID.stringValue] = self.paysValue[payID.stringValue]! + value
                                }
                            }
                            dispatch.leave()
                        })
                        
                        let ppValueRef = self.ref.child(DBPathStrings.payDataPath).child(creator).child(payID.stringValue).child(DBPathStrings.ppPath)
                        dispatch.enter()
                        ppValueRef.observeSingleEvent(of: .value, with: { (snapshot) in
                            let json = JSON(snapshot.value ?? "")
                            for (_, info) in json.dictionaryValue {
                                if let value = info[DBPathStrings.value].float {
                                    self.paysValue[payID.stringValue] = self.paysValue[payID.stringValue]! + value
                                }
                            }
                            dispatch.leave()
                        })
                    }
                    
                    dispatch.notify(queue: .main, execute: {
                        self.segmentTapped(self.chartsSegment)
                    })
                })
            }
        }
    }
    
    func buildBarChart() {
        pieChartViewBG.alpha = 0
        barChartViewBG.alpha = 1
        
        var counter: Double = 0.0
        for (_, value) in paysValue {
            let entry = BarChartDataEntry(x: counter, y: Double(value))
            barChartDataset.append(entry)
            counter += 1.0
        }
        
        let dataset = BarChartDataSet(values: barChartDataset, label: "個別款項")
        dataset.colors = PadiChartColorTemplates.material()
        dataset.valueColors = [.white]
        let data = BarChartData(dataSets: [dataset])
        barChartViewBG.data = data
        
        barChartViewBG.backgroundColor = .black
        barChartViewBG.chartDescription?.textColor = .white
        barChartViewBG.legend.textColor = .white
        barChartViewBG.legend.font = UIFont(name: "Futura", size: 10)!
        barChartViewBG.chartDescription?.font = UIFont(name: "Futura", size: 10)!
        barChartViewBG.chartDescription?.text = "款項花費金額長條圖"
        barChartViewBG.animate(yAxisDuration: 1.2)
        
        barChartViewBG.notifyDataSetChanged()
    }
    
    func buildPieChart() {
        barChartViewBG.alpha = 0
        pieChartViewBG.alpha = 1
        
        var counter: Double = 0.0
        if pieChartDataset.isEmpty {
            for (_, value) in paysValue {
                let entry = PieChartDataEntry(value: Double(value), label: "")
                pieChartDataset.append(entry)
                counter += 1.0
            }
        }
        
        let dataset = PieChartDataSet(values: pieChartDataset, label: "個別款項")
        dataset.colors = PadiChartColorTemplates.material()
        dataset.valueColors = [.white]
        let data = PieChartData(dataSets: [dataset])
        pieChartViewBG.data = data
        
        pieChartViewBG.backgroundColor = .black
        pieChartViewBG.chartDescription?.textColor = .white
        pieChartViewBG.legend.textColor = .white
        pieChartViewBG.legend.font = UIFont(name: "Futura", size: 10)!
        pieChartViewBG.chartDescription?.font = UIFont(name: "Futura", size: 10)!
        pieChartViewBG.chartDescription?.text = "款項花費金額圓餅圖"
        pieChartViewBG.animate(yAxisDuration: 1.2)
        
        pieChartViewBG.notifyDataSetChanged()
    }

}

class PadiChartColorTemplates: ChartColorTemplates {
    
    /* override this func to provide more colors in charts. */
    @objc override class func material () -> [NSUIColor] {
        return [
            NSUIColor(red: 46/255.0, green: 204/255.0, blue: 113/255.0, alpha: 1.0),
            NSUIColor(red: 241/255.0, green: 196/255.0, blue: 15/255.0, alpha: 1.0),
            NSUIColor(red: 231/255.0, green: 76/255.0, blue: 60/255.0, alpha: 1.0),
            NSUIColor(red: 52/255.0, green: 152/255.0, blue: 219/255.0, alpha: 1.0),
            NSUIColor(red: 130/255.0, green: 177/255.0, blue: 255/255.0, alpha: 1.0),
            NSUIColor(red: 141/255.0, green: 110/255.0, blue: 99/255.0, alpha: 1.0),
            NSUIColor(red: 189/255.0, green: 189/255.0, blue: 189/255.0, alpha: 1.0),
            NSUIColor(red: 0/255.0, green: 105/255.0, blue: 92/255.0, alpha: 1.0),
            NSUIColor(red: 245/255.0, green: 0/255.0, blue: 87/255.0, alpha: 1.0),
            NSUIColor(red: 186/255.0, green: 104/255.0, blue: 200/255.0, alpha: 1.0)
        ]
    }
}












