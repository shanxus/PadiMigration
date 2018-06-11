//
//  MemberPayHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftyJSON
import SkeletonView

class MemberPayHelperVC: UIViewController {

    let sharedPayPayerLabelColor = UIColor(red: 237/255, green: 106/255, blue: 90/255, alpha: 1)
    let sharedPayPayeeLabelColor = UIColor(red: 93/255, green: 87/255, blue: 107/255, alpha: 1)
    let ppLabelColor = UIColor(red: 155/255, green: 193/255, blue: 188/255, alpha: 1)
    
    var thisTV: UITableView!
    
    var pay: PadiPay?
    var payID: String?
    var userID: String? {
        didSet {            
            guard let pay = payID, let user = userID else {return}
            
            // why dispatchGroup can not work properly in here.
            fetchPayers(user: user, pay: pay)
            self.fetchPayees(user: user, pay: pay)
            self.fetchPPs(user: user, pay: pay)
        }
    }
    
    /* this dictionary is used to store the key and use it to access image from cache fast. */
    var imgURLDic: [String:String] = [:]
    var memberNameDic: [String:String] = [:]
    
    var payers: [PayPayer] = []
    var payees: [PayPayee] = []
    var pps: [PersonalPay] = []
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    var ppRemoveListener: DatabaseReference?
    var ppAddListener: DatabaseReference?
    
    var payeeRemoveListener: DatabaseReference?
    var payeeAddListener: DatabaseReference?
    var removePayerForAPayeeListener: DatabaseReference?
    
    var payerRemoveListener: DatabaseReference?
    var payerAddListener: DatabaseReference?
    var payerChangeListener: DatabaseReference?
    
    var deleteReminderFinished: Bool = true
    
    func fetchPayers(user: String, pay: String) {
        
        /* listen for delete of payer. */
        payerRemoveListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payerPath)
        payerRemoveListener?.observe(.childRemoved, with: { (snapshot) in
            let removeID = snapshot.key
            for each in self.payers {
                if each.ID == removeID {
                    if let removeIndex = self.payers.index(of: each) {
                        self.payers.remove(at: removeIndex)
                        let indexPath = IndexPath(row: removeIndex, section: 0)
                        self.thisTV.deleteRows(at: [indexPath], with: .fade)                        
                    }
                    break
                }
            }
        })
        
        /* listen for add of payer. */
        payerAddListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payerPath)
        payerAddListener?.observe(.childAdded, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let newPayer = PayPayer(id: snapshot.key, info: json)
            if self.payers.contains(newPayer) {
                // do nothing
            } else {
                self.payers.append(newPayer)
                self.thisTV.reloadData()
            }
        })
        
        /* listen for change of payer. */
        payerChangeListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payerPath)
        payerChangeListener?.observe(.childChanged, with: { (snapshot) in
            let id = snapshot.key
            let json = JSON(snapshot.value ?? "")
            for each in self.payers {
                if each.ID == id {
                    each.payValue = json[DBPathStrings.value].floatValue
                    self.thisTV.reloadData()
                }
                break
            }
        })
    }
    
    func fetchPayees(user: String, pay: String) {
        
        /* listen for delete of payee. */
        payeeRemoveListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payeePath)
        payeeRemoveListener?.observe(.childRemoved, with: { (snapshot) in
            var payerID: String = ""
            
            let removeID = snapshot.key
            
            for each in self.payees {
                if each.ID == removeID {
                    
                    payerID = each.shouldGiveTo
                    
                    if let removeIndex = self.payees.index(of: each) {
                        self.payees.remove(at: removeIndex)
                        let row = removeIndex + self.payers.count
                        let indexPath = IndexPath(row: row, section: 0)
                        self.thisTV.deleteRows(at: [indexPath], with: .fade)
                    }
                    
                    /* handle for the scenario: the payer is invoved and there is no any other payee. */
                    let related = self.relatedPayeeCheck(payerID: payerID)
                    if related == false { // condition met means that the payer should be deleted.
                                                                        
                        let msg = "均分款項已無款項參與人，將刪除此筆均分款項資料"
                        let alert = UIAlertController(title: "提醒", message: msg, preferredStyle: .alert)
                        let sure = UIAlertAction(title: "知道了", style: .default, handler: { (action) in
                            self.deleteReminderFinished = true
                            self.handleRemoveInvolvedPayerForNoRelatedPayee(userID: user, payID: pay, payerID: payerID, completion: nil)
                        })
                        alert.addAction(sure)
                        let topVC = GeneralService.findTopVC()
                        
                        if self.deleteReminderFinished == true {
                            self.deleteReminderFinished = !self.deleteReminderFinished
                            topVC.present(alert, animated: true, completion: nil)
                        }
                    }
                }
            }
         })
        
        /* listen for add of payee. */
        payeeAddListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payeePath)
        payeeAddListener?.observe(.childAdded, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (payerID, _) in json.dictionaryValue {
                let newPayee = PayPayee(ID: snapshot.key, shouldGiveTo: payerID)
                if self.payees.contains(newPayee) {
                    // do nothing.
                } else {
                    // if a payer is involved, not show that record.
                    if newPayee.ID != newPayee.shouldGiveTo {
                        self.payees.append(newPayee)
                        self.thisTV.reloadData()
                    }
                }
            }
        })
        
        /* listen for change of payee. */
        removePayerForAPayeeListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payeePath)
        removePayerForAPayeeListener?.observe(.childChanged, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            self.handlePayeeChange(userID: user, payID: pay, changePayeeID: snapshot.key, snapshot: json)
        })
    }
    
    func fetchPPs(user: String, pay: String) {
        
        /* listen for delete of PPs. */
        ppRemoveListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.ppPath)
        ppRemoveListener?.observe(.childRemoved) { (snapshot) in
            let removeID = snapshot.key
            for eachPP in self.pps {
                if eachPP.id == removeID {
                    if let removeIndex = self.pps.index(of: eachPP) {
                        self.pps.remove(at: removeIndex)
                        let row = removeIndex + self.payers.count + self.payees.count
                        let indexPath = IndexPath(row: row, section: 0)
                        self.thisTV.deleteRows(at: [indexPath], with: .fade)
                    }
                    break
                }
            }
        }
        
        /* listen for add of PPs. */
        ppAddListener = ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.ppPath)
        ppAddListener?.observe(.childAdded, with: { (snapshot) in
            
            let json = JSON(snapshot.value ?? "")
            let newPP = PersonalPay(id: snapshot.key, info: json)
            if self.pps.contains(newPP) {
                // do nothing.
            } else {
                self.pps.append(newPP)
                self.thisTV.reloadData()
            }
        })
    }
    
    func viewDidDisappearNotify() {
        // remove obesevers.
        ppRemoveListener = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /* 'listener for change of payee' will call this function to let UI react to the payee added/deleted */
    func handlePayeeChange(userID: String, payID: String, changePayeeID payee: String, snapshot: JSON) {
        
        var payeesAfterChange: [PayPayee] = []
        var nowPayees: [PayPayee] = []
        
        for (payerID, _) in snapshot.dictionaryValue {
            let newPayee = PayPayee(ID: payee, shouldGiveTo: payerID)
            payeesAfterChange.append(newPayee)
        }
        
        for each in payees {
            if each.ID == payee {
                nowPayees.append(each)
            }
        }
        
        /* react to payee changed */
        if payeesAfterChange.count > nowPayees.count { // detect the added payee and update the UI.
            for each in payeesAfterChange {
                if nowPayees.contains(each) == false {
                    payees.append(each)
                    thisTV.reloadData()
                }
            }
        } else {    // detect the deleted payee and update the UI.
            for each in nowPayees {
                if payeesAfterChange.contains(each) == false {
                    if let removeIndex = payees.index(of: each) {
                        payees.remove(at: removeIndex)
                        let removeIndexPath = IndexPath(row: (removeIndex + payers.count), section: 0)
                        thisTV.deleteRows(at: [removeIndexPath], with: .fade)
                        
                        /* delete a payer when there is a call of .childChanged for payee and
                         * there is no related payee.
                         */
                        let check = relatedPayeeCheck(payerID: each.shouldGiveTo)
                        if check == false {
                            var msg: String = ""
                            if let payerName = memberNameDic[each.shouldGiveTo] {
                                msg = "均分款項付款者\(payerName)已無款項參與人，將刪除此付款者資料"
                            }
                            let alert = UIAlertController(title: "提醒", message: msg, preferredStyle: .alert)
                            let sure = UIAlertAction(title: "知道了", style: .default) { (action) in
                                self.deleteReminderFinished = true
                                self.handleRemovePayer(userID: userID, payID: payID, payerID: each.shouldGiveTo)
                            }
                            alert.addAction(sure)
                            let topVC = GeneralService.findTopVC()
                            if deleteReminderFinished == true {
                                deleteReminderFinished = !deleteReminderFinished
                                topVC.present(alert, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /*
     * for a payer ID, check is there any payee related to that payer.
     */
    func relatedPayeeCheck(payerID: String) -> Bool {
        var isRelated = false
        for payee in payees {
            if payee.shouldGiveTo == payerID && payee.ID != payerID {
                isRelated = true
                break
            }
        }
        return isRelated
    }
    
    func handleLongPressInPayRecordsTV(longPressedIndex index: IndexPath, completion: @escaping ((_ finished: Bool) -> Void)) {
        
        guard let pay = payID, let user = userID else {return}
        let helper = ExamplePay()
        
        /* to know which kind of record had been tapped. */
        if (index.row > (payers.count - 1)) == false {  // tapped in payers.
            let payer = payers[index.row]
            var msg: String = ""
            
            if let payerName = memberNameDic[payer.ID], let value = payer.payValue {
                msg = "均分款項付款者: \(payerName)\n付款金額: \(value)"
            }
            
            let alert = UIAlertController(title: "編輯均分款項", message: msg, preferredStyle: .actionSheet)
            let delete = UIAlertAction(title: "刪除", style: .destructive) { (action) in
                let remindMsg = "刪除均分款項付款者的話，此筆均分款項的其它付款者以及參與者也會一併刪除，確定嗎?"
                let deleteReminder = UIAlertController(title: "提醒", message: remindMsg, preferredStyle: .alert)
                let sureDelete = UIAlertAction(title: "確定", style: .destructive, handler: { (action) in
                    self.handleRemovePayerAndRelatedPayess(userID: user, payID: pay, completion: {
                        completion(true)
                    })
                })
                let cancelDelete = UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
                    completion(true)
                })
                deleteReminder.addAction(sureDelete)
                deleteReminder.addAction(cancelDelete)
                
                let topVC = GeneralService.findTopVC()
                topVC.present(deleteReminder, animated: true, completion: nil)
            }
            
            let editValue = UIAlertAction(title: "編輯金額", style: .default) { (action) in
                
                let valueAlert = UIAlertController(title: "金額", message: "請輸入新的金額", preferredStyle: .alert)
                valueAlert.addTextField(configurationHandler: { (tf) in
                    if let value = payer.payValue {
                        tf.placeholder = "\(value)"
                    }
                    tf.keyboardType = .decimalPad
                })
                let sure = UIAlertAction(title: "確定", style: .default, handler: { (action) in
                    let tf = valueAlert.textFields![0] as UITextField
                    guard let txt = tf.text, txt != "" else { return }
                    
                    let changePayerPayValueRef = self.ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payerPath).child(payer.ID).child(DBPathStrings.value)
                    changePayerPayValueRef.setValue(Float(txt))
                    completion(true)
                })
                let cancelEdit = UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
                    completion(true)
                })
                valueAlert.addAction(sure)
                valueAlert.addAction(cancelEdit)
                
                let topVC = GeneralService.findTopVC()
                topVC.present(valueAlert, animated: true, completion: nil)
            }
            
            let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                completion(true)
            }
            alert.addAction(delete)
            alert.addAction(editValue)
            alert.addAction(cancel)
            
            let topVC = GeneralService.findTopVC()
            topVC.present(alert, animated: true, completion: nil)
            
        } else if index.row > (payers.count - 1), (index.row > (payers.count + payees.count - 1)) == false {    // tapped in payees.
            
            let payee = payees[index.row - payers.count]
            var msg: String = ""
            if let payeeName = memberNameDic[payee.ID], let payerName = memberNameDic[payee.shouldGiveTo] {
                msg = "款項參與者: \(payeeName)\n付款者: \(payerName)"
            }
            let alert = UIAlertController(title: "編輯均分款項", message: msg, preferredStyle: .actionSheet)
            let delete = UIAlertAction(title: "刪除", style: .destructive) { (action) in
                
                let payeeRemoveTargetRef = self.ref.child(DBPathStrings.payDataPath).child(user).child(pay).child(DBPathStrings.payeePath).child(payee.ID).child(payee.shouldGiveTo)
                payeeRemoveTargetRef.removeValue()
                
                completion(true)
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                completion(true)
            }
            alert.addAction(delete)
            alert.addAction(cancel)
            
            let topVC = GeneralService.findTopVC()
            topVC.present(alert, animated: true, completion: nil)
            
        } else {    // tapped in pps.
            let pp = pps[index.row - (payers.count+payees.count)]
            var msg: String = ""
            
            if let payerName = memberNameDic[pp.payerID], let payeeName = memberNameDic[pp.belongsToMember] {
                msg = "\(payerName) 幫 \(payeeName) 付款"
            }
            
            let alert = UIAlertController(title: "編輯個人款項", message: msg, preferredStyle: .actionSheet)
            
            let delete = UIAlertAction(title: "刪除", style: .destructive, handler: { (action) in
                helper.delete(personalPayID: pp.id, payID: pay, userID: user)
                
                completion(true)
            })
            
            let cancel = UIAlertAction(title: "取消", style: .cancel, handler: { (action) in
                completion(true)
            })
            
            alert.addAction(delete)
            alert.addAction(cancel)
            
            let topVC = GeneralService.findTopVC()
            topVC.present(alert, animated: true, completion: nil)
        }
    }
    
    func handleRemovePayer(userID: String, payID: String, payerID: String) {
        let targetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payerPath).child(payerID)
        targetRef.removeValue()
    }
    
    /* this works for the scenario: when user delete any payer of a shared pay. */
    func handleRemovePayerAndRelatedPayess(userID: String, payID: String, completion: (() -> Void)?) {
        let payerRemoveTarget = self.ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payerPath)
        payerRemoveTarget.removeValue()
        
        let payeeRemoveTarget = self.ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payeePath)
        payeeRemoveTarget.removeValue()
        completion?()
    }
    
    /* this works for the scenario: payer is involved. */
    func handleRemoveInvolvedPayerForNoRelatedPayee(userID: String, payID: String, payerID: String, completion: (() -> Void)?) {
        
        let targetPayerRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payerPath)
        
        targetPayerRef.removeValue()
        
        let targetPayeeRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payeePath).child(payerID)
        targetPayeeRef.removeValue()
        
        completion?()
    }
}

extension MemberPayHelperVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = payers.count + payees.count + pps.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "MemberShouldPayTVC", for: indexPath) as? MemberShouldPayTVC {
            
            let memberHelper = ExamplePadiMember()
            
            if (indexPath.row > (payers.count - 1)) == false { // show for payers.
                cell.shouldPayTitle.text = "均分款項付款者"
                cell.shouldPayTitle.textColor = sharedPayPayerLabelColor
                
                let payer = payers[indexPath.row]
                
                if imgURLDic[payer.ID] == nil {
                    cell.memberImage.isSkeletonable = true
                    cell.memberImage.showAnimatedGradientSkeleton()
                    memberHelper.fetchUserImageURL(userID: payer.ID) { (url: String) in
                        let imgURL = URL(string: url)
                        self.imgURLDic[payer.ID] = url
                        DispatchQueue.main.async {
                            cell.memberImage.kf.setImage(with: imgURL)
                            cell.memberImage.hideSkeleton()
                        }
                    }
                } else {
                    let url = URL(string: imgURLDic[payer.ID]!)
                    cell.memberImage.kf.setImage(with: url)
                }
                
                if memberNameDic[payer.ID] == nil {
                    cell.memberName.isSkeletonable = true
                    cell.memberName.showAnimatedGradientSkeleton()
                    memberHelper.fetchName(userID: payer.ID) { (name: String) in
                        DispatchQueue.main.async {
                            cell.memberName.text = name
                            cell.memberName.hideSkeleton()
                        }
                    }
                } else {
                    cell.memberName.text = memberNameDic[payer.ID]!
                }
                
                if let value = payer.payValue {
                    cell.shouldPayValue.text = "\(value)"
                }
            } else if indexPath.row > (payers.count - 1), (indexPath.row > (payers.count + payees.count - 1)) == false { // show for payees
                cell.shouldPayTitle.text = "均分款項參與者"
                cell.shouldPayTitle.textColor = sharedPayPayeeLabelColor
                let payee = payees[indexPath.row - payers.count]
                
                if imgURLDic[payee.ID] == nil {
                    memberHelper.fetchUserImageURL(userID: payee.ID) { (url: String) in
                        let imgURL = URL(string: url)
                        self.imgURLDic[payee.ID] = url
                        DispatchQueue.main.async {
                            cell.memberImage.kf.setImage(with: imgURL)
                            cell.memberImage.hideSkeleton()
                        }
                    }
                } else {
                    let url = URL(string: imgURLDic[payee.ID]!)
                    cell.memberImage.kf.setImage(with: url)
                }
                
                if memberNameDic[payee.ID] == nil {
                    cell.memberName.isSkeletonable = true
                    cell.memberName.showAnimatedGradientSkeleton()
                    memberHelper.fetchName(userID: payee.ID) { (name: String) in
                        DispatchQueue.main.async {
                            cell.memberName.text = name
                            cell.memberName.hideSkeleton()
                        }
                    }
                } else {
                    cell.memberName.text = memberNameDic[payee.ID]!
                }
                
                if memberNameDic[payee.shouldGiveTo] == nil {
                    cell.shouldPayValue.isSkeletonable = true
                    cell.shouldPayValue.showAnimatedGradientSkeleton()
                    memberHelper.fetchName(userID: payee.shouldGiveTo) { (name: String) in
                        self.memberNameDic[payee.shouldGiveTo] = name
                        DispatchQueue.main.async {
                            cell.shouldPayValue.text = "付款者: \(name)"
                            cell.shouldPayValue.hideSkeleton()
                        }
                    }
                } else {
                    cell.shouldPayValue.text = "付款者: \(memberNameDic[payee.shouldGiveTo]!)"
                }
            } else { // show for pps.
                
                cell.shouldPayTitle.text = "個人款項"
                cell.shouldPayTitle.textColor = ppLabelColor
                
                let pp = pps[indexPath.row - (payers.count+payees.count)]
                
                if imgURLDic[pp.payerID] == nil {
                    cell.memberImage.isSkeletonable = true
                    cell.memberImage.showAnimatedGradientSkeleton()
                    memberHelper.fetchUserImageURL(userID: pp.payerID) { (url: String) in
                        let imgURL = URL(string: url)
                        self.imgURLDic[pp.payerID] = url
                        DispatchQueue.main.async {
                            cell.memberImage.kf.setImage(with: imgURL)
                            cell.memberImage.hideSkeleton()
                        }
                    }
                } else {
                    let url = URL(string: imgURLDic[pp.payerID]!)
                    cell.memberImage.kf.setImage(with: url)
                }
                
                if memberNameDic[pp.payerID] == nil {
                    cell.memberName.isSkeletonable = true
                    cell.memberName.showAnimatedGradientSkeleton()
                    memberHelper.fetchName(userID: pp.payerID) { (name: String) in
                        self.memberNameDic[pp.payerID] = name
                        DispatchQueue.main.async {
                            cell.memberName.text = name
                            cell.memberName.hideSkeleton()
                        }
                    }
                } else {
                    cell.memberName.text = memberNameDic[pp.payerID]!
                }
                
                if memberNameDic[pp.belongsToMember] == nil {
                    cell.shouldPayValue.isSkeletonable = true
                    cell.shouldPayValue.showAnimatedGradientSkeleton()
                    memberHelper.fetchName(userID: pp.belongsToMember) { (name: String) in
                        self.memberNameDic[pp.belongsToMember] = name
                        DispatchQueue.main.async {
                            cell.shouldPayValue.text = "幫 \(name) 付款"
                            cell.shouldPayValue.hideSkeleton()
                        }
                    }
                } else {
                    cell.shouldPayValue.text = "幫 \(memberNameDic[pp.belongsToMember]!) 付款"
                }
            }
            return cell
        }
        
        return UITableViewCell()
    }
}

extension MemberPayHelperVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}






