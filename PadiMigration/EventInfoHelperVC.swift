//
//  EventInfoHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftyJSON
import SkeletonView

class EventInfoHelperVC: UIViewController {

    var userID: String?    
    var eventID: String? {
        didSet {
            
        }
    }
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }        
}

extension EventInfoHelperVC: UITableViewDelegate {
    
    
}

extension EventInfoHelperVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = userID, let event = eventID else {return UITableViewCell()}
        let helper = ExamplePadiEvent()
        if indexPath.row == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventInfoDetailTVC", for: indexPath) as? EventInfoDetailTVC {
                cell.detailTitle.text = "活動名稱"
                cell.detailDescription.isSkeletonable = true
                cell.detailDescription.showAnimatedGradientSkeleton()
                helper.fetchEventName(userID: user, eventID: event) { (name: String) in
                    DispatchQueue.main.async {
                        cell.detailDescription.text = name
                        cell.detailDescription.hideSkeleton()
                    }
                }                
                return cell
            }
        } else if indexPath.row == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventInfoDetailTVC", for: indexPath) as? EventInfoDetailTVC {
                cell.detailTitle.text = "時間"
                cell.detailDescription.isSkeletonable = true
                cell.detailDescription.showAnimatedGradientSkeleton()
                helper.fetchAttribute(for: DBPathStrings.timePath, eventID: event, userID: user) { (fetched: JSON) in
                    let timeString = EntityHelperClass.getPadiEntityDateString(with: fetched.doubleValue)
                    DispatchQueue.main.async {
                        cell.detailDescription.text = timeString
                        cell.detailDescription.hideSkeleton()
                    }
                }
                return cell
            }
        } else if indexPath.row == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventInfoDetailTVC", for: indexPath) as? EventInfoDetailTVC {
                cell.detailTitle.text = "花費"
                cell.detailDescription.isSkeletonable = true
                cell.detailDescription.showAnimatedGradientSkeleton()
                helper.fetchTotalValue(userID: user, eventID: event) { (value: Float) in
                    DispatchQueue.main.async {
                        cell.detailDescription.text = "$ \(value)"
                        cell.detailDescription.hideSkeleton()
                    }
                }                
                return cell
            }
        } else if indexPath.row == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventInfoDetailTVC", for: indexPath) as? EventInfoDetailTVC {
                cell.detailTitle.text = "款項數"
                cell.detailDescription.isSkeletonable = true
                cell.detailDescription.showAnimatedGradientSkeleton()
                helper.fetchPayCount(userID: user, eventID: event) { (count: Int) in
                    DispatchQueue.main.async {
                        cell.detailDescription.text = "\(count)"
                        cell.detailDescription.hideSkeleton()
                    }
                }                
                return cell
            }
        }else if indexPath.row == 4 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventInfoDetailTVC", for: indexPath) as? EventInfoDetailTVC {
                cell.detailTitle.text = "成員個數"
                cell.detailDescription.isSkeletonable = true
                cell.detailDescription.showAnimatedGradientSkeleton()
                helper.fetchMemberList(userID: user, eventID: event) { (memberList: [String]) in
                    DispatchQueue.main.async {
                        cell.detailDescription.text = "\(memberList.count)"
                        cell.detailDescription.hideSkeleton()
                    }
                }
                return cell
            }
        }
        
        
        return UITableViewCell()
    }
    
    
}










