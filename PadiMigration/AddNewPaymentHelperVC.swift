//
//  AddNewPaymentHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/14.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftyJSON
import SwiftMessages

class AddNewPaymentHelperVC: UIViewController {

    let headerColor = UIColor(red: 255/255, green: 248/255, blue: 237/255, alpha: 1)
    var thisTableViewInstance: UITableView?
    
    var modeFooterDescription: String? {
        didSet {
            guard let thisTableView = thisTableViewInstance else {return}
            thisTableView.reloadData()
        }
    }
    
    var memberSelectDescription: String? {
        didSet {
            guard let thisTableView = thisTableViewInstance else {return}
            thisTableView.reloadData()
        }
    }
    
    var mode: payShareMode? {
        didSet {            
            if mode == payShareMode.sharedPay {
                memberSelectDescription = "在均分模式下，所有款項參與成員將一同均分付款者所付之金額（個人款項除外）。"
            } else if mode == payShareMode.notSharedPay {
                memberSelectDescription = "在不均分模式下，請個別設定所有款項參與成員的個人應付金額。"
            } else {
                memberSelectDescription = ""
            }
            
            //serviceChargeValue = "無"
        }
    }
    
    var isServiceChargeValueChanged: Bool = false
    var serviceChargeValue: String? {
        didSet {
            guard let thisTableView = thisTableViewInstance else {return}
            thisTableView.reloadData()
        }
    }
    
    var selectedPayers: [String:Float] = [:]
    var selectedPayees: [String] = []
    var selectedPairs: [PersonalPayInfo] = []
    
    var eventID: String? {
        didSet {
            guard let eventID = eventID, let userID = Auth.auth().currentUser?.uid else {return}
            let helper = ExamplePadiEvent()
            helper.getMemberList(forSingleEvent: eventID, userID: userID) { (memberList) in
                self.memberList = memberList
            }
        }
    }
    
    var mainUserID: String?
    
    /* this variable is for editing view. */
    var editPayID: String? {
        didSet {
            let helper = ExamplePay()
            guard let pay = editPayID, let user = mainUserID else {return}
            
            /* load payers*/
            helper.fetchPayAttribute(for: DBPathStrings.payerPath, payID: pay, userID: user) { (fetched: JSON) in
                for (key, info) in fetched.dictionaryValue {
                    let value = info[DBPathStrings.value].floatValue
                    self.selectedPayers[key] = value
                }
            }
            
            /* load payees */
            helper.fetchPayAttribute(for: DBPathStrings.payeePath, payID: pay, userID: user) { (fetched: JSON) in
                for (key, _) in fetched.dictionaryValue {
                    self.selectedPayees.append(key)
                }
            }
            
            /* load pp */
            var memberList: [String] = []
            var ppsList: [PersonalPay] = []
            helper.fetchPayAttribute(for: DBPathStrings.memberListPath, payID: pay, userID: user) { (fetched: JSON) in
                for id in fetched.arrayValue {
                    memberList.append(id.stringValue)
                }
            }
            helper.fetchPayAttribute(for: DBPathStrings.ppPath, payID: pay, userID: user) { (fetched: JSON) in
                for (key, info) in fetched.dictionaryValue {
                    let newPP = PersonalPay(id: key, info: info)
                    ppsList.append(newPP)
                }
                
                for each in ppsList {
                    if let payerIndex = memberList.index(of: each.payerID) {
                        if let payeeIndex = memberList.index(of: each.belongsToMember) {
                            let newPPInfo = PersonalPayInfo(id: each.id, payerIndex: payerIndex, payeeIndex: payeeIndex, payerID: each.payerID, payeeID: each.belongsToMember, value: String(each.value))
                            self.selectedPairs.append(newPPInfo)
                        }
                    }
                }
            }
        }
    }
    
    var isAbleToShowInspectionView: Bool? {
        didSet {
            guard let thisTableView = thisTableViewInstance else {return}
            thisTableView.reloadData()
        }
    }
    
    var date: TimeInterval?
    
    var memberList: [String]?
    
    var hasImageChanged: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func infoNotEnoughAlert() {
        let alert = UIAlertController(title: "必要資訊不足", message: "請填好新增款項所有的必要資訊，如款項名稱以及款項圖片", preferredStyle: .alert)
        let sureAction = UIAlertAction(title: "知道了", style: .default, handler: nil)
        alert.addAction(sureAction)
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }
    
    /* To check whether the info in AddNewPaymentHelperVC is enough. */
    func handleCheckActionBlockInfo() -> Bool {
        
        if isAbleToShowInspectionView == false {
            return false
        }
        
        guard let _ = serviceChargeValue else {
            return false
        }
        
        return true
    }
    
    func checkIsPayerInvolved(payerID payer: String, selectedPayees payees: [String]) -> Bool {
        for each in payees {
            if payer == each {
                return true
            }
        }
        return false
    }
    
    func handleTransformPayers(selectedPayers: [String:Float], selectedPayees: [String]) -> [PayPayer] {
        var payers: [PayPayer] = []
        
        for (key, value) in selectedPayers {
            let check = checkIsPayerInvolved(payerID: key, selectedPayees: selectedPayees)
            let newPayer = PayPayer(withPayValue: value, ID: key, isInvolved: check)
            payers.append(newPayer)
        }
        return payers
    }
    
    func handleTransformPayees(selectedPayers: [String:Float], selectedPayees: [String]) -> [PayPayee] {
        var payees: [PayPayee] = []
        
        /**
         if payer are multiple, the number of payee object with same payee ID will be multiple too.
         */
        for (key, _) in selectedPayers {
            for payee in selectedPayees {
                let newPayee = PayPayee(ID: payee, shouldGiveTo: key)
                payees.append(newPayee)
            }
        }
        return payees
    }
    
    func handleTransformPP(selectedPairs: [PersonalPayInfo]) -> [PersonalPay] {
        var PPs: [PersonalPay] = []
        
        for each in selectedPairs {
            guard let id = each.id else {return PPs}
            let payer = each.payerID!
            let payee = each.payeeID!
            if let value = Float(each.value!) {
                let newPP = PersonalPay(withID: id, Payer: payer, belongsTo: payee, value: value)
                PPs.append(newPP)
            }
        }
        return PPs
    }
    
    func handleAddingNewPayment(belongsToEvent: String?, paymentNameLabel: UILabel?, imageType: String) {
        guard let belongsToEvent = belongsToEvent, let payName = paymentNameLabel?.text, payName != "請輸入款項名稱", imageType != "" else {
            infoNotEnoughAlert()
            return
        }
        
        let infoCheck = handleCheckActionBlockInfo()
        if infoCheck == false {
            infoNotEnoughAlert()
        } else {
            
            /* dismiss the view. */
            // it can be done by using a indicator view to let user know that it is working on save the new added pay.
            let topVC = GeneralService.findTopVC()
            topVC.dismiss(animated: true, completion: nil)
            
            /*
             transform selected payers, selected payees and personalPays into entity objects to calculate the PayRelations.
             */
            let payers = handleTransformPayers(selectedPayers: selectedPayers, selectedPayees: selectedPayees)
            let payees = handleTransformPayees(selectedPayers: selectedPayers, selectedPayees: selectedPayees)
            let pps = handleTransformPP(selectedPairs: selectedPairs)
            
            guard let member = self.memberList else {return}            
            
            /* create new pay object */
            let newPayID = UUID().uuidString
            let date = Date()
            let newPayDate = date.timeIntervalSince1970
            guard let chargedValue = serviceChargeValue else {return}
            
            if let storedValue = Float(chargedValue) {
                let newPayObject = PadiPay(payID: newPayID, belongsToEventID: belongsToEvent, name: payName, imageURL: imageType, dateTimeInterval: newPayDate, memberList: member, isServiceCharged: false, serviceChargeValue: storedValue, payerList: payers, payeeList: payees, personalPayList: pps)
                
                let storeHelper = ExamplePay()
                guard let currentUserID = Auth.auth().currentUser?.uid else {return}
                storeHelper.storeIntoDB(pay: newPayObject, userID: currentUserID)
                /* swiftMessage. */
                let msgView = MessageView.viewFromNib(layout: .cardView)
                msgView.button?.removeFromSuperview()
                msgView.configureContent(title: "新增款項成功", body: "您新增了一筆分款款項")
                msgView.configureTheme(.success)
                msgView.configureDropShadow()
                SwiftMessages.show(view: msgView)
            }
        }
    }
    
    func handleSavingChanges(forPay payID: String, userID: String, imageType: String, newTitle: String?) {
        
        let check = checkCalculateSharedPayRequirementIsMet()
        if check == false {
            infoNotEnoughAlert()
        } else {
            let topVC = GeneralService.findTopVC()
            topVC.dismiss(animated: true, completion: nil)
            
            let payHelper = ExamplePay()
            
            payHelper.store(imgURL: imageType, payID: payID, userID: userID)
            
            if let newTitle = newTitle {
                payHelper.store(name: newTitle, payID: payID, userID: userID)
            }
            
            let payers = handleTransformPayers(selectedPayers: selectedPayers, selectedPayees: selectedPayees)
            payHelper.store(payers: payers, payID: payID, userID: userID)
            
            let payees = handleTransformPayees(selectedPayers: selectedPayers, selectedPayees: selectedPayees)
            payHelper.store(payees: payees, payID: payID, userID: userID)
            
            // should think a smarter way to update this.
            let pps = handleTransformPP(selectedPairs: selectedPairs)
            payHelper.update(personalPay: pps, payID: payID, userID: userID)
            
            if let value = serviceChargeValue, let storedValue = Float(value) {
                payHelper.store(serviceCharge: storedValue, payID: payID, userID: userID)
            }
        }
    }
    
    func handleCellInteraction(cell: AddNewPaymentActionBlockTVC, interaction: Bool) {
        cell.actionTitle.layer.opacity = interaction ? 1.0 : 0.5
        cell.descriptionLabel.layer.opacity = interaction ? 1.0 : 0.5
        cell.indicatorLabel.layer.opacity = interaction ? 1.0 : 0.5
        cell.isUserInteractionEnabled = interaction ? true : false
    }
    
    func clearUpAllSelectedInformation() {
        selectedPayers.removeAll()
        selectedPayees.removeAll()
        selectedPairs.removeAll()
    }
    
    func handlePayserSelect() {
        let topVC = GeneralService.findTopVC()
        if let handlePayerSelectVC = topVC.storyboard?.instantiateViewController(withIdentifier: "PayerSelectVC") as? PayInvolvedSelectVC {
            handlePayerSelectVC.VCType = InvolvedMemberType.payer
            handlePayerSelectVC.selectedPayers = selectedPayers
            handlePayerSelectVC.handleSelectedPayersDelegate = self
            if let eventID = eventID {
                handlePayerSelectVC.eventID = eventID
            }
            topVC.present(handlePayerSelectVC, animated: true, completion: nil)
        }
    }
    
    func handlePayeeSelect() {
        let topVC = GeneralService.findTopVC()
        if let payeeSelectVC = topVC.storyboard?.instantiateViewController(withIdentifier: "PayerSelectVC") as? PayInvolvedSelectVC {
            payeeSelectVC.VCType = InvolvedMemberType.payee
            payeeSelectVC.selectedPayees = selectedPayees
            payeeSelectVC.handleSelectedPayeesDelegate = self
            if let eventID = eventID {
                payeeSelectVC.eventID = eventID
            }
            topVC.present(payeeSelectVC, animated: true, completion: nil)
        }
    }
    
    func handleAddingPersonalPay() {
        let topVC = GeneralService.findTopVC()
        if let AddingPPVC = topVC.storyboard?.instantiateViewController(withIdentifier: "addPPVC") as? AddNewPersonalPayVC {
            if let id = eventID {
                AddingPPVC.eventID = id
                AddingPPVC.selectedPairHolder = selectedPairs
                AddingPPVC.passSelectedPairsDelegate = self
            }
            topVC.present(AddingPPVC, animated: true, completion: nil)
        }
    }
    
    func handlePresentServiceCharge() {
        let topVC = GeneralService.findTopVC()
        
        let alert = UIAlertController(title: "服務費", message: "選擇服務費，或自訂", preferredStyle: .actionSheet)
        let no = UIAlertAction(title: "無", style: .default) { (action) in
            self.serviceChargeValue = "0"
            self.isServiceChargeValueChanged = true
        }
        let one = UIAlertAction(title: "一成", style: .default) { (action) in
            self.serviceChargeValue = "10"
            self.isServiceChargeValueChanged = true
        }
        let userDefind = UIAlertAction(title: "自訂", style: .default) { (action) in
            // should show alert to let user input the value.
            let alert = UIAlertController(title: "自訂服務費", message: "請輸入數值，例如 10% 請輸入 10", preferredStyle: .alert)
            let action = UIAlertAction(title: "確定", style: .default) { (action) in
                let tf = alert.textFields![0] as UITextField
                
                if let value = Float(tf.text!) {
                    if value > 0 && value != 0 {
                        
                        self.serviceChargeValue = "\(value)"
                        self.isServiceChargeValueChanged = true
                    }
                }
            }
            alert.addTextField { (tf) in
                tf.placeholder = "10"
                tf.keyboardType = .decimalPad
            }
            alert.addAction(action)
            topVC.present(alert, animated: true, completion: nil)
        }
        alert.addAction(no)
        alert.addAction(one)
        alert.addAction(userDefind)
        
        topVC.present(alert, animated: true, completion: nil)
    }
    
    /* 
     when there is shared pay, check does the requirement to
     calculate shared value is met (that is, both payer and
     payee are selected).
     **/
    func checkCalculateSharedPayRequirementIsMet() -> Bool {
        let selectedPayerCount = selectedPayers.count
        let selectedPayeeCount = selectedPayees.count
        if (selectedPayerCount != 0 || selectedPayeeCount != 0) && selectedPayerCount * selectedPayeeCount == 0 {
            if isAbleToShowInspectionView != false {
                isAbleToShowInspectionView = false
            }
            return false
        } else {
            if isAbleToShowInspectionView != true {
                isAbleToShowInspectionView = true
            }
            return true
        }
    }
}

extension AddNewPaymentHelperVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "eventActionBlock", for: indexPath) as? AddNewPaymentActionBlockTVC {
            
            let helper = ExamplePay()
            
            cell.indicatorLabel.text = ""
            
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell.actionTitle.text = "時間"
                    handleCellInteraction(cell: cell, interaction: false)
                    if let pay = editPayID, let user = mainUserID { /* condition satisfied only in editing pay */
                        helper.fetchPayAttribute(for: DBPathStrings.timePath, payID: pay, userID: user, completion: { (fetched: JSON) in
                            let timeString = EntityHelperClass.getPadiEntityDateString(with: fetched.doubleValue)
                            cell.descriptionLabel.text = timeString
                        })
                    } else {
                        let nowDate = EntityHelperClass.getDateNow()
                        date = nowDate
                        let nowDateString = EntityHelperClass.getPadiEntityDateString(with: nowDate)
                        cell.indicatorLabel.layer.opacity = 0
                        cell.descriptionLabel.text = nowDateString
                    }
                    return cell
                }
            } else if indexPath.section == 1{
                if indexPath.row == 0 {
                    cell.actionTitle.text = "選擇付款者"
                    cell.descriptionLabel.text = ""
                    handleCellInteraction(cell: cell, interaction: true)
                    return cell
                } else {
                    handleCellInteraction(cell: cell, interaction: true)
                    cell.actionTitle.text = "選擇參與款項成員"
                    cell.descriptionLabel.text = ""
                    return cell
                }
            } else if indexPath.section == 2 {
                handleCellInteraction(cell: cell, interaction: true)
                cell.actionTitle.text = "新增個人款項"
                cell.descriptionLabel.text = ""
                return cell
            } else if indexPath.section == 3 {
                    handleCellInteraction(cell: cell, interaction: true)
                    cell.actionTitle.text = "服務費"
                    handleCellInteraction(cell: cell, interaction: false)
                    if let pay = editPayID, let user = mainUserID, isServiceChargeValueChanged == false {
                        helper.fetchPayAttribute(for: DBPathStrings.serviceChargePath, payID: pay, userID: user, completion: { (fetched: JSON) in
                            cell.descriptionLabel.text = "\(fetched.floatValue) %"
                        })
                    } else {
                        if let value = serviceChargeValue, let displayValue = Float(value) {
                            cell.descriptionLabel.text = "\(displayValue) %"
                        } else {
                            cell.descriptionLabel.text = "無"
                            serviceChargeValue = "0"
                        }
                    }
                    return cell
            } else {
                let check = checkCalculateSharedPayRequirementIsMet()
                if check == true {
                    handleCellInteraction(cell: cell, interaction: true)
                } else {
                    handleCellInteraction(cell: cell, interaction: false)
                }
                cell.actionTitle.text = "檢視"
                cell.descriptionLabel.text = ""
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 30
        } else if section == 2 {
            return 30
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = headerColor
        if section == 1 {
            var descriptionLabel: UILabel {
                let des = UILabel(frame: CGRect(x: 10, y: 10, width: tableView.bounds.width-10, height: 50))
                des.text = "均分款項"
                des.textColor = UIColor.darkGray
                des.numberOfLines = 0
                des.font = UIFont.boldSystemFont(ofSize: 13)
                des.sizeToFit()
                return des
            }
            headerView.addSubview(descriptionLabel)
            return headerView
        } else if section == 2 {
            var descriptionLabel: UILabel {
                let des = UILabel(frame: CGRect(x: 10, y: 10, width: tableView.bounds.width-10, height: 50))
                des.text = "個人款項"
                des.textColor = UIColor.darkGray
                des.numberOfLines = 0
                des.font = UIFont.boldSystemFont(ofSize: 13)
                des.sizeToFit()
                return des
            }
            headerView.addSubview(descriptionLabel)
            return headerView
        } else {
            return headerView
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = headerColor
        if section == 0 {
            var descriptionLabel: UILabel {
                let des = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                des.text = "款項時間尚未開放修改。"
                des.textColor = .lightGray
                des.numberOfLines = 0
                des.font = UIFont.systemFont(ofSize: 13)
                des.sizeToFit()
                return des
            }
            footerView.addSubview(descriptionLabel)
            return footerView

        } else if section == 1 {
            var paymentMemberDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                descriptionLabel.text = "新增均分款項：可選擇多位付款者，以及各付款者之付款金額。所選擇之參與成員將會一同均分款項金額。"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(paymentMemberDescription)
            return footerView
        } else if section == 2 {
            var paymentMemberDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                descriptionLabel.text = "新增個人款項：直接選擇一對一的付款者、付款金額以及款項成員。"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(paymentMemberDescription)
            return footerView
        } else if section == 3 {
            var paymentMemberDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                descriptionLabel.text = "服務費功能尚未開放"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(paymentMemberDescription)
            return footerView
        } else {
            var paymentMemberDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                descriptionLabel.text = "在儲存之前檢視已建立之款項。"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(paymentMemberDescription)
            return footerView
        }
    }
}

extension AddNewPaymentHelperVC: UITableViewDelegate {
    
    func handleShowInspectionVC() {
        let topVC = GeneralService.findTopVC()
        let inspectionVC = InspectionVC()
        inspectionVC.selectedPayers = selectedPayers
        inspectionVC.selectedPayees = selectedPayees
        inspectionVC.selectedPairs = selectedPairs
        topVC.present(inspectionVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                handlePayserSelect()
            } else if indexPath.row == 1 {
                handlePayeeSelect()
            }
        } else if indexPath.section == 2 {
            handleAddingPersonalPay()
        } else if indexPath.section == 3 {            
            handlePresentServiceCharge()
        } else if indexPath.section == 4 {
            handleShowInspectionVC()
        }
    }
}

extension AddNewPaymentHelperVC: PassSelectedInvolvedPayer {
    func passSelectedInvolvedPayerBack(info: [String : Float]) {
        selectedPayers = info
        let _ = checkCalculateSharedPayRequirementIsMet()
    }
}

extension AddNewPaymentHelperVC: PassSelectedInvoledPayee {
    func passSelectedInvolvedIDBack(IDs: [String]) {
        selectedPayees = IDs
        let _ = checkCalculateSharedPayRequirementIsMet()
    }
}

extension AddNewPaymentHelperVC: PassSelectedPersonalPay {
    func passSelectedPersonalPay(pairs: [PersonalPayInfo]) {
        self.selectedPairs = pairs
    }
}






