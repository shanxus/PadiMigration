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

    let headerColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
    
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

        NotificationCenter.default.addObserver(self, selector: #selector(AddNewPaymentVC.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
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
        
        handleGenerateDummyPayImage()
        
        prepareForEditingPay(isEditing: self.isEditingPay)
    }

    @IBAction func addNewPaymentTapped(_ sender: Any) {
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
    
    @objc func rotated() {
        handleGenerateDummyPayImage()
    }
    
    func handleGenerateDummyPayImage() {
        guard let thisTableView = paymentInfoBlockTableView else {return}
        let imgIndexPath = IndexPath(row: 0, section: 0)
        guard let cell = thisTableView.cellForRow(at: imgIndexPath) as? AddNewPaymentInfoBlockTVC else {return}
        if let imgView = cell.paymentImage {
            
            paymentImgView = imgView
            let frame = imgView.frame
            
            let dummyImgView = UIView(frame: frame)
            dummyImgView.isUserInteractionEnabled = true
            dummyImgView.backgroundColor = UIColor.clear
            dummyImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangePayImage)))
            cell.addSubview(dummyImgView)
        }
    }
    
    @objc func handleChangePayImage() {
        let topVC = GeneralService.findTopVC()
        if let defaultIconVC = topVC.storyboard?.instantiateViewController(withIdentifier: "DefaultPayIconVC") as? DefaultIconSelectVC {
            defaultIconVC.delegate = self
            topVC.present(defaultIconVC, animated: true, completion: nil)
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
        
        // should refactor this getting thisTableView code later.
        guard let thisTableView = paymentInfoBlockTableView else {return}
        let index = IndexPath(row: 0, section: 0)
        guard let cell = thisTableView.cellForRow(at: index) as? AddNewPaymentInfoBlockTVC else {return}
        guard let payNameForNow = cell.paymentTitle.text else {return}
        paymentNameLabel = cell.paymentTitle
        
        let topVC = GeneralService.findTopVC()
        if let showEditTxtFieldVC = self.storyboard?.instantiateViewController(withIdentifier: "showEditTxtFieldVC") as? ShowEditTxtFieldVC {
            
            let txtInfo = EditTxtInfo(flag: Flag.addEventName.rawValue, titleTxt: "更改款項名稱", inputTxt: payNameForNow, actionTxt: "儲存")
            showEditTxtFieldVC.viewTxtPrepare = txtInfo
            showEditTxtFieldVC.passEventNameDelegate = self
            // delegate here
            topVC.present(showEditTxtFieldVC, animated: true, completion: nil)
        }
    }
}

extension AddNewPaymentVC: PassEventNameBack {
    func passEventName(event name: String) {
        paymentNameLabel?.text = name
    }
}

extension AddNewPaymentVC: defaultIconSelectionDelegate {
    func pass(selectedType: String) {
        
        selectedDefaultIconName = selectedType
        paymentImgView?.image = UIImage(named: selectedType)
    }
}









