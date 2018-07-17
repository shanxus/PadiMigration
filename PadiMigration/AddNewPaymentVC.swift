//
//  AddNewPaymentVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/14.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import SwiftyJSON

class AddNewPaymentVC: UIViewController {

    let headerColor = UIColor(red: 255/255, green: 248/255, blue: 237/255, alpha: 1)
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var paymentInfoBlockTableView: UITableView!
    @IBOutlet weak var paymentActionBlockTableView: UITableView!
    @IBOutlet weak var infoBlockCellHeightConstraint: NSLayoutConstraint!
    let addNewPaymentHelper = AddNewPaymentHelperVC()
    
    var belongsToEventID: String?
    
    var paymentImgView: UIImageView?
    var paymentImgData: Data?
    var paymentNameLabel: UILabel?
    
    @IBOutlet weak var addButton: UIButton!
    
    /* variables for editing view. */
    var isEditingPay: Bool = false
    var payID: String?
    var userID: String?
    
    var hasImageChanged: Bool? {
        didSet {
            if let changed = hasImageChanged {
                addNewPaymentHelper.hasImageChanged = changed
            }
        }
    }
    
    var selectedDefaultIconName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        paymentInfoBlockTableView.dataSource = self
        paymentInfoBlockTableView.delegate = self
        paymentInfoBlockTableView.tableFooterView = UIView()
        paymentInfoBlockTableView.isScrollEnabled = false
        
        paymentActionBlockTableView.backgroundColor = headerColor
        paymentActionBlockTableView.dataSource = addNewPaymentHelper
        paymentActionBlockTableView.delegate = addNewPaymentHelper
        
        /* pass for editing view. */
        if let pay = payID, let user = userID, let event = belongsToEventID {
            addNewPaymentHelper.mainUserID = user
            addNewPaymentHelper.editPayID = pay
            addNewPaymentHelper.eventID = event
        }
        
        addNewPaymentHelper.thisTableViewInstance = paymentActionBlockTableView
        if let eventID = belongsToEventID {
            addNewPaymentHelper.eventID = eventID
        }
        
        prepareForEditingPay(isEditing: self.isEditingPay)
    }

    @IBAction func addNewPaymentTapped(_ sender: Any) {
        
        let payInfoCellIndex = IndexPath(row: 0, section: 0)
        guard let infoCell = paymentInfoBlockTableView.cellForRow(at: payInfoCellIndex) as? AddNewPaymentInfoBlockTVC else {return}
        paymentNameLabel = infoCell.paymentTitle
        
        if self.isEditingPay == true {  // saving changes for a existing pay.
            guard let pay = payID, let user = userID else {return}
            addNewPaymentHelper.handleSavingChanges(forPay: pay, userID: user, imageType: selectedDefaultIconName, newTitle: paymentNameLabel?.text)
        } else {    // saving new created pay.
            
            addNewPaymentHelper.handleAddingNewPayment(belongsToEvent: belongsToEventID, paymentNameLabel: paymentNameLabel, imageType: selectedDefaultIconName)
        }
    }
    
    @IBAction func dismissAddNewPaymentView(_ sender: Any) {
        // add a alert before dismissing.
        self.dismiss(animated: true, completion: nil)
    }
    
    /* execute this for preparing showing editing view */
    func prepareForEditingPay(isEditing: Bool) {
        if isEditing == true {
            handleLoadingViewTitle(isEditing: isEditing)
        }
    }
    
    func handleLoadingViewTitle(isEditing: Bool) {
        if isEditing == true {
            viewTitle.text = "編輯款項"
            addButton.setTitle("儲存", for: .normal)
        } else {
            viewTitle.text = "新增款項"
            addButton.setTitle("新增", for: .normal)
        }
    }
}

extension AddNewPaymentVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventInfoBlock", for: indexPath) as! AddNewPaymentInfoBlockTVC
        cell.paymentImage.contentMode = .scaleAspectFill
        
        cell.selectedPayIconDelegate = self
        
        if isEditingPay == false {
            cell.paymentTitle.text = "請輸入款項名稱"
            cell.paymentImage.image = #imageLiteral(resourceName: "PadiPayDefault")
        } else {
            guard let pay = payID, let user = userID else {return UITableViewCell()}
            let helper = ExamplePay()
            
            helper.fetchPayAttribute(for: DBPathStrings.namePath, payID: pay, userID: user, completion: { (fetched: JSON) in
                DispatchQueue.main.async {
                    let name = fetched.stringValue
                    cell.paymentTitle.text = name
                }
            })
            
            helper.fetchPayImage(payID: pay, userID: user) { (type: String) in
                DispatchQueue.main.async {
                    cell.paymentImage.image = UIImage(named: type)
                    self.selectedDefaultIconName = type
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        // dynamically change the height for the cell.
        let cellHight = cell.bounds.height
        infoBlockCellHeightConstraint.constant = cellHight
    }
}

extension AddNewPaymentVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension AddNewPaymentVC: defaultIconSelectionDelegate {
    func pass(selectedType: String) {
        
        selectedDefaultIconName = selectedType
        paymentImgView?.image = UIImage(named: selectedType)
    }
}









