//
//  AddPersonalPayVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/25.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseAuth

class PersonalPayInfo {
    var id: String?
    var payerIndex: Int?
    var payeeIndex: Int?
    var payerID: String?
    var payeeID: String?
    var value: String?
    init(id: String,payerIndex: Int, payeeIndex: Int, payerID: String, payeeID: String, value: String) {
        self.id = id
        self.payerIndex = payerIndex
        self.payeeIndex = payeeIndex
        self.payerID = payerID
        self.payeeID = payeeID
        self.value = value
    }
}

class AddNewPersonalPayVC: UIViewController {

    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var payerTitleBG: UIView!
    @IBOutlet weak var payerTitle: UILabel!
    @IBOutlet weak var payersCV: UICollectionView!
    @IBOutlet weak var payeesCV: UICollectionView!
    @IBOutlet weak var recordsTableView: UITableView!
    
    let showPayeesListHelper: ShowPayeesHelperVC! = ShowPayeesHelperVC()
    
    var selectedPairHolder: [PersonalPayInfo] = []
    var selectedPair: [PersonalPayInfo]? {
        didSet {
            recordsTableView.reloadData()
        }
    }
    
    var selectedPayeeIndex: Int? {
        didSet {
            if let index = selectedPayeeIndex, let list = membersIDList {
                selectedPayeeID = list[index]
            }
        }
    }
    var selectedPayerIndex: Int? {
        didSet {
            if let index = selectedPayerIndex, let list = membersIDList {
                selectedPayerID = list[index]
            }
            
            if let payeeIndex = selectedPayeeIndex, let payerIndex = selectedPayerIndex, let payeeID = selectedPayeeID, let payerID = selectedPayerID{
                
                handleGetPPValue(completion: { (valueString) in
                    if valueString == "invalid" {
                        // should show reminder here.
                    } else {
                        let uid = UUID().uuidString
                        let newPPInfoObj = PersonalPayInfo(id: uid, payerIndex: payerIndex, payeeIndex: payeeIndex, payerID: payerID, payeeID: payeeID, value: valueString)
                        self.selectedPair?.append(newPPInfoObj)
                    }
                })
            }
            
            selectedPayeeIndex = nil
            selectedPayerIndex = nil
        }
    }
    var selectedPayeeID: String?
    var selectedPayerID: String?
    
    var isPayeeSelected: Bool?    
    var isPayerSelected: Bool? {
        didSet {
            isPayeeSelected = nil
            isPayerSelected = nil
            
            /* remove scaled animations. */
            if let payeeImgView = payeeCell?.memberImage {
                payeeImgView.layer.removeAllAnimations()
                payeeCell = nil
            }
            if let payerImgView = payerCell?.payerImage {
                payerImgView.layer.removeAllAnimations()
                payerCell = nil
            }
        }
    }
    
    var payerCell: PayersListCVC?
    var payeeCell: PayeesListCVC?
    
    var membersIDList: [String]? {
        didSet {
            payeesCV.reloadData()
        }
    }
    
    var eventID: String? {
        didSet {
            guard let eventID = eventID , let userID = Auth.auth().currentUser?.uid else {return}
            let helper = ExamplePadiEvent()
            helper.getMemberList(forSingleEvent: eventID, userID: userID) { (memberList:[String]) in
                self.membersIDList = memberList
                self.showPayeesListHelper.membersIDList = memberList
                self.payeesCV.reloadData()
            }
        }
    }
    
    var passSelectedPairsDelegate: PassSelectedPersonalPay?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        payersCV.dataSource = self
        payersCV.delegate = self
        
        payeesCV.dataSource = showPayeesListHelper
        payeesCV.delegate = showPayeesListHelper
        
        recordsTableView.dataSource = self
        recordsTableView.delegate = self
        recordsTableView.tableFooterView = UIView()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.7
        self.view.addGestureRecognizer(longPress)
        
        selectedPair = selectedPairHolder
        
    }

    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if let pairs = selectedPair {
            passSelectedPairsDelegate?.passSelectedPersonalPay(pairs: pairs)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleGetPPValue(completion: @escaping ((_ valueString: String) -> Void)) {
        let alert = UIAlertController(title: "金額", message: "請輸入個人款項金額", preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = "請輸入金額"
            tf.keyboardType = .decimalPad
        }
        let sureAction = UIAlertAction(title: "確定", style: .default) { (action) in
            let tf = alert.textFields![0] as UITextField
            guard let txt = tf.text, txt != "" else {
                completion("invalid")
                return
            }
            completion(txt)
        }
        alert.addAction(sureAction)
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        
        if let press = gestureRecognizer as? UILongPressGestureRecognizer {
            let state = press.state
            switch state {
                
            // selection should begin with selecting a payee
            case .began:
                if let _ = isPayeeSelected {
                    
                } else {
                    let locationInPayees = press.location(in: payeesCV)
                    if let locationInPayerList = payeesCV.indexPathForItem(at: locationInPayees) {
                        selectedPayeeIndex = locationInPayerList.item
                        
                        if let cell = payeesCV.cellForItem(at: locationInPayerList) as? PayeesListCVC {
                            payeeCell = cell
                            cell.memberImage.scaledAniamtion()
                        }
                        
                        isPayeeSelected = true
                    }
                }
            case .changed:
                if let _ = isPayeeSelected {
                    let locationInPayers = press.location(in: payersCV)
                    if let locationInPayerList = payersCV.indexPathForItem(at: locationInPayers) {
                        if let cell = payersCV.cellForItem(at: locationInPayerList) as? PayersListCVC {
                            if let _ = payerCell, payerCell !== cell {
                                payerCell?.payerImage.layer.removeAllAnimations()
                            }
                            if payerCell !== cell {
                                payerCell = cell
                                cell.payerImage.scaledAniamtion()
                            }
                        }
                    }
                }
            case .ended:
                if let _ = isPayeeSelected {
                    let locationInPayers = press.location(in: payersCV)
                    if let locationInPayerList = payersCV.indexPathForItem(at: locationInPayers) {
                        selectedPayerIndex = locationInPayerList.item
                        
                        isPayerSelected = true
                    }
                }
            default:
                print("")
            }
        }
    }
}

extension AddNewPersonalPayVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = membersIDList?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "payerListCVC", for: indexPath) as? PayersListCVC {
            let helper = ExamplePadiFriends()
            guard let list = membersIDList else {return UICollectionViewCell()}
            helper.getImageURLString(forSingleFriend: list[indexPath.row], completion: { (url) in
                let imgURL = URL(string: url)
                cell.payerImage.kf.setImage(with: imgURL)
            })                        
            return cell
        }
        return UICollectionViewCell()
    }
}

extension AddNewPersonalPayVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension AddNewPersonalPayVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 20.0
        
        return CGSize(width: 80, height: 100)
    }
}

extension AddNewPersonalPayVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = selectedPair?.count else {
            let reminderTxt = UILabel()
            reminderTxt.font = UIFont.systemFont(ofSize: 13)
            reminderTxt.alpha = 0.8
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
            reminderTxt.frame = frame
            reminderTxt.textAlignment = .center
            reminderTxt.text = "您還沒有建立任何一筆個人款項哦！\n透過先按著成員，再將手指拖移到某一位付款者來新增個人款項吧！"
            reminderTxt.numberOfLines = 0
            reminderTxt.sizeToFit()
            tableView.backgroundView = reminderTxt
            return 0
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ppRecordsTVC", for: indexPath) as? NewPersonalPayRecordsTVC {
            let helper = ExamplePadiFriends()
            guard let pairedPayer = selectedPair?[indexPath.row].payerIndex else {return UITableViewCell()}
            guard let pairedPayee = selectedPair?[indexPath.row].payeeIndex else {return UITableViewCell()}
            guard let value = selectedPair?[indexPath.row].value else {return UITableViewCell()}
            guard let list = membersIDList else {return UITableViewCell()}
            
            let payerID = list[pairedPayer]
            let payeeID = list[pairedPayee]
            
            helper.getImageURLString(forSingleFriend: payerID, completion: { (url) in
                let imgURL = URL(string: url)
                cell.payerImage.kf.setImage(with: imgURL)
            })
            
            helper.getImageURLString(forSingleFriend: payeeID, completion: { (url) in
                let imgURL = URL(string: url)
                cell.payeeImage.kf.setImage(with: imgURL)
            })
            
            cell.relation.text = "應該付$\(value)給"
            
            return cell
        }
        return UITableViewCell()
    }
    
}

extension AddNewPersonalPayVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
















