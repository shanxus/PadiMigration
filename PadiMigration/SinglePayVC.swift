//
//  SinglePayVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

class SinglePayVC: UIViewController {

    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var layoutTableView: UITableView!
    
    let infoHelper: SinglePayInfoHelperVC! = SinglePayInfoHelperVC()
    let memberPayHelper: MemberPayHelperVC! = MemberPayHelperVC()
    
    var userID: String?
    var payID: String?
    var eventID: String?
    
    @IBOutlet weak var editBtn: UIButton!
    var isEditingBtnShowing: Bool = true
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    var payListener: DatabaseReference?
    
    var payRecords: UITableView!
    
    var memberPaymentTV: UITableView!
    var isPayRecordEditAlertFinished: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if isEditingBtnShowing == false {
            editBtn.isUserInteractionEnabled = false
            editBtn.alpha = 0.0
        }
        
        layoutTableView.delegate = self
        layoutTableView.dataSource = self
        layoutTableView.tableFooterView = UIView()
        
        if let user = userID, let pay = payID {
            listenForPayChange(userID: user, payID: pay)
        }
        
        addLongPressRecognizer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        payListener = nil
    }
    
    func addLongPressRecognizer() {
        let rec = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressInPayRecords))
        let layoutIndex = IndexPath(row: 0, section: 3)
        if let cell = layoutTableView.cellForRow(at: layoutIndex) as? SinglePayMemberTVC {
            memberPaymentTV = cell.memberPaymentTableView
            cell.memberPaymentTableView.addGestureRecognizer(rec)
        }
    }
    
    @objc func handleLongPressInPayRecords(gestureRecognizer: UIGestureRecognizer) {
        if isPayRecordEditAlertFinished == true {
            isPayRecordEditAlertFinished = !isPayRecordEditAlertFinished
            
            let pressLocation = gestureRecognizer.location(in: memberPaymentTV)
            if let index = memberPaymentTV.indexPathForRow(at: pressLocation) {
                memberPayHelper.handleLongPressInPayRecordsTV(longPressedIndex: index, completion: { (alertFinished) in
                    self.isPayRecordEditAlertFinished = alertFinished
                })
            }
        }
    }
    
    func listenForPayChange(userID: String, payID: String) {
        payListener = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payListener?.observe(.childChanged, with: { (snapshot) in
            
            /* listen for change of pay image. */
            if snapshot.key == DBPathStrings.imageURLPath {
                let index = IndexPath(row: 0, section: 0)
                if let cell = self.layoutTableView.cellForRow(at: index) as? SinglePayImageTVC {
                    let json = JSON(snapshot.value ?? "")
                    let imageURL = URL(string: json.stringValue)
                    cell.payImage.kf.setImage(with: imageURL)
                }
            }
            
            /* listen for change of pay name. */
            if snapshot.key == DBPathStrings.namePath {
                let layoutIndex = IndexPath(row: 0, section: 2)
                let infoIndex = IndexPath(row: 0, section: 0)
                self.updateInfoBlockTable(firstLayerIndex: layoutIndex, secondLayerIndex: infoIndex, snapshot: snapshot, shouldChangeViewTitle: true, value: nil, isUsingValue: false, isServiceCharge: false, isMemberCount: false)
            }
            
            // should add listener for change of pay time here if time is changable to user.
            
            /* listen for change of pay value. */
            if snapshot.key == DBPathStrings.ppPath || snapshot.key == DBPathStrings.payerPath || snapshot.key == DBPathStrings.payeePath {
                self.payValueUpdator(payID: payID, userID: userID, snapshot: snapshot)
            }
            
            /* listen for change of member count. */
            if snapshot.key == DBPathStrings.memberListPath {
                let layoutIndex = IndexPath(row: 0, section: 2)
                let infoIndex = IndexPath(row: 3, section: 0)
                
                let json = JSON(snapshot.value ?? "")
                let count = json.floatValue
                
                self.updateInfoBlockTable(firstLayerIndex: layoutIndex, secondLayerIndex: infoIndex, snapshot: snapshot, shouldChangeViewTitle: false, value: count, isUsingValue: true, isServiceCharge: false, isMemberCount: true)
            }
            
            /* listen for change of service charge. */
            if snapshot.key == DBPathStrings.serviceChargePath {
                let layoutIndex = IndexPath(row: 0, section: 2)
                let infoIndex = IndexPath(row: 4, section: 0)
                
                let json = JSON(snapshot.value ?? "")
                
                self.updateInfoBlockTable(firstLayerIndex: layoutIndex, secondLayerIndex: infoIndex, snapshot: snapshot, shouldChangeViewTitle: false, value: json.floatValue, isUsingValue: true, isServiceCharge: true, isMemberCount: false)
            }
        })
        
        payListener?.observe(.childRemoved, with: { (snapshot) in
            if snapshot.key == DBPathStrings.ppPath || snapshot.key == DBPathStrings.payerPath || snapshot.key == DBPathStrings.payeePath {
                self.payValueUpdator(payID: payID, userID: userID, snapshot: snapshot)
            }
        })
    }
    
    func payValueUpdator(payID: String, userID: String, snapshot: DataSnapshot) {
        let valueHelper = ExamplePay()
        valueHelper.getPayValue(ofSinglePay: payID, userID: userID, completion: { (value: Float) in
            let layoutIndex = IndexPath(row: 0, section: 2)
            let infoIndex = IndexPath(row: 2, section: 0)
            self.updateInfoBlockTable(firstLayerIndex: layoutIndex, secondLayerIndex: infoIndex, snapshot: snapshot, shouldChangeViewTitle: false, value: value, isUsingValue: true, isServiceCharge: false, isMemberCount: false)
        })
    }
    
    func updateInfoBlockTable(firstLayerIndex: IndexPath, secondLayerIndex: IndexPath, snapshot: DataSnapshot, shouldChangeViewTitle: Bool, value: Float?, isUsingValue: Bool, isServiceCharge: Bool, isMemberCount: Bool) {
        if let layoutCell = self.layoutTableView.cellForRow(at: firstLayerIndex) as? SinglePayInfoTVC {
            let infoTable = layoutCell.infoTableView
            if let nameCell = infoTable?.cellForRow(at: secondLayerIndex) as? SinglePayInfoDetailTVC {
                if isUsingValue == false {
                    let json = JSON(snapshot.value ?? "")
                    nameCell.infoDescription.text = json.stringValue
                    
                    DispatchQueue.main.async {
                        if shouldChangeViewTitle == true {
                            self.viewTitle.text = json.stringValue
                        }
                    }
                } else {
                    if isServiceCharge == true {
                        DispatchQueue.main.async {
                            if let value = value {
                                nameCell.infoDescription.text = "\(value) %"
                            }
                        }
                    } else if isMemberCount == true {
                        DispatchQueue.main.async {
                            if let value = value {
                                nameCell.infoDescription.text = "\(Int(value))"
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            if let value = value {
                                nameCell.infoDescription.text = "$ \(value)"
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func settingTapped(_ sender: Any) {
        guard let pay = payID, let user = userID, let event = eventID else {return}
        let topVC = GeneralService.findTopVC()
        if let editingView = topVC.storyboard?.instantiateViewController(withIdentifier: "addNewPaymentVC") as? AddNewPaymentVC {
            editingView.isEditingPay = true
            editingView.userID = user
            editingView.payID = pay
            editingView.belongsToEventID = event
            topVC.present(editingView, animated: true, completion: nil)
        }
    }
    
    @IBAction func dismissSinglePayVC(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }    
}

extension SinglePayVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let topVC = GeneralService.findTopVC()
            if let showRelationVC = topVC.storyboard?.instantiateViewController(withIdentifier: "showPayRelationVC") as? ShowPayRelationVC {
                showRelationVC.userID = userID!
                showRelationVC.payIDs = [payID!]
                /* This is the push from right to left transition animation.
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromRight
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                */
                topVC.present(showRelationVC, animated: true, completion: nil)
            }
        }
    }
}

extension SinglePayVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 180
        } else if indexPath.section == 1 {
            return 40
        } else if indexPath.section == 2 {
            return 150
        } else {
            return self.view.bounds.height*0.66
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SinglePayImageCell", for: indexPath) as? SinglePayImageTVC {
                if let user = userID, let pay = payID {
                    let imgURLRef = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.imageURLPath)
                    imgURLRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        let json = JSON(snapshot.value ?? "")
                        if let url = URL(string: json.stringValue) {
                            cell.payImage.kf.setImage(with: url)
                        }
                    })
                }
                return cell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "ShowPaymentCell", for: indexPath) as? ShowPaymentForSinglePayTVC {
                cell.title.text = "顯示款項付款資訊"
                cell.indicatorLabel.text = ">"
                return cell
            }
        } else if indexPath.section == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "PayInfoCell", for: indexPath) as? SinglePayInfoTVC {
                cell.title.text = "款項資訊"
                if let pay = payID, let user = userID {
                    infoHelper.payID = pay
                    infoHelper.userID = user
                }
                cell.infoTableView.dataSource = self.infoHelper
                cell.infoTableView.delegate = self.infoHelper
                return cell
            }
        } else if indexPath.section == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SinglePayMembersTVC", for: indexPath) as? SinglePayMemberTVC {
                cell.title.text = "款項紀錄"
                if let pay = payID, let user = userID {
                    memberPayHelper.thisTV = cell.memberPaymentTableView
                    memberPayHelper.payID = pay
                    memberPayHelper.userID = user
                }
                cell.memberPaymentTableView.dataSource = self.memberPayHelper
                cell.memberPaymentTableView.delegate = self.memberPayHelper
                cell.memberPaymentTableView.tableFooterView = UIView()
                return cell
            }
        }
        
        return UITableViewCell()
    }
}










