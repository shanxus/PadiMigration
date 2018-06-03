//
//  PayerSelectVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/24.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseAuth

typealias payerInfo = [Int:Float]

enum InvolvedMemberType: String {
    case payer = "選擇付款者"
    case payee = "選擇款項參與者"
}

class PayInvolvedSelectVC: UIViewController {

    @IBOutlet weak var memberListTableView: UITableView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    
    var mainUserID: String? {
        didSet {
            guard let userID = mainUserID else {return}
            guard let eventID = eventID else {return}
            
            let helper = ExamplePadiEvent()
            helper.getMemberList(forSingleEvent: eventID, userID: userID) { (memberList) in
                self.friends = memberList
                self.prepareSelectedInfo()
            }
        }
    }
    
    var friends: [String]? {
        didSet {
            self.memberListTableView.reloadData()
        }
    }
    
    /* when VCType is .payer, use this variable to store selected info (selected payer index and its pay vlaue). */
    fileprivate var selectedInfo: payerInfo? {
        didSet {
            self.memberListTableView.reloadData()
        }
    }
    
    var selectedPayers: [String:Float] = [:]
    var selectedPayees: [String] = []
    
    var VCType: InvolvedMemberType?
    
    var handleSelectedPayersDelegate: PassSelectedInvolvedPayer?
    var handleSelectedPayeesDelegate: PassSelectedInvoledPayee?
    
    var eventID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedInfo = [:]
        memberListTableView.delegate = self
        memberListTableView.dataSource = self
        memberListTableView.tableFooterView = UIView()
        
        getMainUserID()
        handleShowTitle()
    }

    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func storeTapped(_ sender: Any) {
        guard let type = VCType else {return}
        if type == .payer {
            handleSelectedPayersDelegate?.passSelectedInvolvedPayerBack(info: selectedPayers)
        } else {
            handleSelectedPayeesDelegate?.passSelectedInvolvedIDBack(IDs: selectedPayees)
        }
        self.dismiss(animated: true, completion: nil)
    }

    func prepareSelectedInfo() {
        guard let friends = friends else {return}
        for each in selectedPayers {
            if let index = friends.index(of: each.key) {
                selectedInfo?[index] = each.value
            }
        }
    }
    
    func handleAddSelectedPayee(index: Int) {
        guard let friends = friends else {return}
        let id = friends[index]
        selectedPayees.append(id)
    }
    
    func handleRemoveSelectedPayee(index: Int) {
        guard let friends = friends else {return}
        let removeID = friends[index]
        if let removeIndex = selectedPayees.index(of: removeID) {
            selectedPayees.remove(at: removeIndex)
        }
    }
    
    func handleAddSelectedPayer(index: Int, value: Float) {
        guard let friends = friends else {return}
        let id = friends[index]
        selectedPayers[id] = value
    }
    
    func handleRemoveSelectedPayer(index: Int) {
        guard let friends = friends else {return}
        let id = friends[index]
        selectedPayers.removeValue(forKey: id)
    }
    
    func getMainUserID() {
        if let currentUserID = Auth.auth().currentUser?.uid {
            mainUserID = currentUserID
        }

    }
    
    func handleShowTitle() {
        guard let type = VCType?.rawValue else {return}
        if let title = viewTitleLabel {
            title.text = type
        }
    }
}

extension PayInvolvedSelectVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = friends?.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "payerSelectTVC", for: indexPath) as? PayerSelectTVC {
            let helper = ExamplePadiFriends()
            if let friends = friends {
                helper.getImageURLString(forSingleFriend: friends[indexPath.row], completion: { (url) in
                    let imgURL = URL(string: url)
                    cell.memberImage.kf.setImage(with: imgURL)
                })
                
                helper.getName(forSingleFriend: friends[indexPath.row], completion: { (name) in
                    cell.memberName.text = name
                })
            }
            
            if VCType == InvolvedMemberType.payer {
                if let value = selectedInfo?[indexPath.row] {
                    cell.payerPayValue.text = "$ \(value)"
                    cell.accessoryType = .checkmark
                } else {
                    cell.payerPayValue.text = ""
                }
            } else {
                cell.payerPayValue.text = ""
                if let friends = friends {
                    let id = friends[indexPath.row]
                    if selectedPayees.contains(id) == true {
                        cell.accessoryType = .checkmark
                    } else {
                        cell.accessoryType = .none
                    }
                }
            }
            return cell
        }
        return UITableViewCell()
    }
}

extension PayInvolvedSelectVC: UITableViewDelegate {
    
    func handleGeneratePayValueAlert(index: Int, completion: @escaping ((_ result: Bool) -> Void)) -> UIAlertController {
        let alert = UIAlertController(title: "付款金額", message: "請輸入付款者付款金額", preferredStyle: .alert)
        let action = UIAlertAction(title: "確定", style: .default) { (action) in
            let tf = alert.textFields![0] as UITextField
            
            if let value = Float(tf.text!) {
                if value > 0 && value != 0 {
                    self.selectedInfo?[index] = value
                    self.handleAddSelectedPayer(index: index, value: value)
                    completion(true)
                }
            }            
        }
        alert.addTextField { (tf) in
            tf.placeholder = "value"
            tf.keyboardType = .decimalPad
        }
        alert.addAction(action)
        return alert
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else {return}
        
        if VCType == InvolvedMemberType.payer {
            if cell.accessoryType == .checkmark {
                
                let _ = selectedInfo?.removeValue(forKey: indexPath.row)
                cell.accessoryType = .none
                handleRemoveSelectedPayer(index: indexPath.row)
                
            } else {
                let alert = handleGeneratePayValueAlert(index: indexPath.row, completion: { (result) in
                    if result == true {
                        cell.accessoryType = cell.accessoryType == .checkmark ? .none : .checkmark
                    }
                })
                let topVC = GeneralService.findTopVC()
                topVC.present(alert, animated: true, completion: nil)
            }
        } else {
            guard let friends = friends else {return}
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                handleRemoveSelectedPayee(index: indexPath.row)
            } else {
                cell.accessoryType = .checkmark
                handleAddSelectedPayee(index: indexPath.row)
            }
        }
    }
}














