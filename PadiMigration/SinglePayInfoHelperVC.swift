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
                helper.fetchPayAttribute(for: DBPathStrings.namePath, payID: payID, userID: userID, completion: { (fetchedValue: JSON) in
                    let name = fetchedValue.stringValue
                    cell.infoDescription.text = name
                })
                return cell
            }
        } else if indexPath.row == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "時間"
                helper.fetchPayAttribute(for: DBPathStrings.timePath, payID: payID, userID: userID, completion: { (fetchedValue: JSON) in
                    let time = fetchedValue.double
                    let timeString = EntityHelperClass.getPadiEntityDateString(with: time!)
                    cell.infoDescription.text = timeString
                })                
                return cell
            }
        } else if indexPath.row == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "花費"
                helper.fetchPayValue(userID: userID, payID: payID) { (value: Float) in
                    DispatchQueue.main.async {
                        cell.infoDescription.text = "$ \(value)"
                    }
                }                
                return cell
            }
        } else if indexPath.row == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "成員數"
                helper.fetchPayAttribute(for: DBPathStrings.memberListPath, payID: payID, userID: userID, completion: { (fetchedValue) in
                    let members = fetchedValue.arrayValue
                    let count = members.count
                    cell.infoDescription.text = "\(count)"
                })
                return cell
            }
        /*
         }
         else if indexPath.row == 4 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "均分模式"
                cell.infoTitle.textColor = UIColor.lightGray
                // should keep this property?
                cell.infoDescription.text = "--"
                cell.infoDescription.textColor = .lightGray
                return cell
        }
        */
        } else if indexPath.row == 4 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "服務費"
                helper.fetchPayAttribute(for: DBPathStrings.serviceChargePath, payID: payID, userID: userID, completion: { (fetchedValue) in
                    cell.infoDescription.text = "\(fetchedValue.stringValue) %"
                })

                return cell
            }
        }
        /*
        else if indexPath.row == 6 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoDetailTVC", for: indexPath) as? SinglePayInfoDetailTVC {
                cell.infoTitle.text = "退稅"
                cell.infoTitle.textColor = UIColor.lightGray
                cell.infoDescription.text = "--"
                cell.infoDescription.textColor = .lightGray
                return cell
            }
        }
        */
        return UITableViewCell()
    }
}

extension SinglePayInfoHelperVC: UITableViewDelegate {
    
}
