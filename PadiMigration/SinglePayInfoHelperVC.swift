//
//  SinglePayInfoHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftyJSON
import SkeletonView

class SinglePayInfoHelperVC: UIViewController {
    
    var payID: String?
    var userID: String?
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
}

extension SinglePayInfoHelperVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let payID = payID, let userID = userID else {return UITableViewCell()}
        let helper = ExamplePay()
        
        if indexPath.row == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "款項名稱"
                
                cell.infoDescription.isSkeletonable = true
                cell.infoDescription.showAnimatedSkeleton()
                helper.fetchPayName(payID: payID, userID: userID) { (name: String) in
                    DispatchQueue.main.async {
                        cell.infoDescription.text = name
                        cell.hideSkeleton()
                    }
                }
                return cell
            }
        } else if indexPath.row == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "時間"
                
                cell.infoDescription.isSkeletonable = true
                cell.infoDescription.showAnimatedSkeleton()
                helper.fetchPayAttribute(for: DBPathStrings.timePath, payID: payID, userID: userID, completion: { (fetchedValue: JSON) in
                    let time = fetchedValue.double
                    let timeString = EntityHelperClass.getPadiEntityDateString(with: time!)
                    DispatchQueue.main.async {
                        cell.infoDescription.text = timeString
                        cell.infoDescription.hideSkeleton()
                    }
                })                
                return cell
            }
        } else if indexPath.row == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "花費"
                
                cell.infoDescription.isSkeletonable = true
                cell.infoDescription.showAnimatedSkeleton()
                helper.fetchPayValue(userID: userID, payID: payID) { (value: Float) in
                    DispatchQueue.main.async {
                        cell.infoDescription.text = "$ \(value)"
                        cell.infoDescription.hideSkeleton()
                    }
                }                
                return cell
            }
        } else if indexPath.row == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "成員數"
                
                cell.infoDescription.isSkeletonable = true
                cell.infoDescription.showAnimatedSkeleton()
                helper.fetchMemberList(payID: payID, userID: userID) { (list: [String]) in
                    DispatchQueue.main.async {
                        cell.infoDescription.text = "\(list.count)"
                        cell.infoDescription.hideSkeleton()
                    }
                }
                return cell
            }
        } else if indexPath.row == 4 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                // this is 服務費 block, implement or remove this later.
                cell.infoTitle.text = ""
                
                cell.infoDescription.isSkeletonable = true
                cell.infoDescription.showAnimatedSkeleton()
                helper.fetchPayAttribute(for: DBPathStrings.serviceChargePath, payID: payID, userID: userID, completion: { (fetchedValue) in
                    DispatchQueue.main.async {
                        cell.infoDescription.text = ""
                        cell.infoDescription.hideSkeleton()
                    }
                })
                return cell
            }
        }
        return UITableViewCell()
    }
}

extension SinglePayInfoHelperVC: UITableViewDelegate {
    
}
