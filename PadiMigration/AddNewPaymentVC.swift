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
            addNewPaymentHelper.handleSavingChanges(forPay: pay, userID: user, imageData: paymentImgData, newTitle: paymentNameLabel?.text)
        } else {    // saving new created pay.
            addNewPaymentHelper.handleAddingNewPayment(belongsToEvent: belongsToEventID, paymentNameLabel: paymentNameLabel, imageData: paymentImgData)
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
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let topVC = GeneralService.findTopVC()
        
        let alert = UIAlertController(title: "更改款項圖片", message: "請選擇圖片來源，或者繼續使用預設圖片", preferredStyle: .actionSheet)
        let fromPhotoLibrary = UIAlertAction(title: "相片圖庫", style: .default) { (action) in
            imagePicker.sourceType = .photoLibrary
            topVC.present(imagePicker, animated: true, completion: nil)
        }
        let fromCamera = UIAlertAction(title: "相機", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                topVC.present(imagePicker, animated: true, completion: nil)
            }
        }
        let fromDefault = UIAlertAction(title: "使用預設圖片", style: .default) { (action) in
            if let defaultIconVC = topVC.storyboard?.instantiateViewController(withIdentifier: "DefaultPayIconVC") as? DefaultIconSelectVC {
                topVC.present(defaultIconVC, animated: true, completion: nil)
            }
        }
        let cancel = UIAlertAction(title: "取消", style: .destructive) { (action) in
            
        }
        alert.addAction(fromPhotoLibrary)
        alert.addAction(fromCamera)
        alert.addAction(fromDefault)
        alert.addAction(cancel)
        
        topVC.present(alert, animated: true, completion: nil)
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
                let name = fetched.stringValue
                cell.paymentTitle.text = name
            })
            
            if let selectedPayImage = paymentImgView?.image {
                cell.paymentImage.image = selectedPayImage
            } else {
                helper.fetchPayAttribute(for: DBPathStrings.imageURLPath, payID: pay, userID: user, completion: { (fetched: JSON) in
                    let imgURL = URL(string: fetched.stringValue)
                    cell.paymentImage.kf.setImage(with: imgURL)
                    DispatchQueue.main.async {
                        self.paymentInfoBlockTableView.reloadData()
                    }
                })
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

extension AddNewPaymentVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImg = info[UIImagePickerControllerOriginalImage] as! UIImage
        guard let resizedImg = UIImageJPEGRepresentation(selectedImg, 0.3) else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        paymentImgData = resizedImg
        if let img = UIImage(data: resizedImg) {
            paymentImgView?.image = img
            
            /* call didSet to notify image has been changed when editing a view. */
            if isEditingPay == true {
                hasImageChanged = true
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension AddNewPaymentVC: PassEventNameBack {
    func passEventName(event name: String) {
        paymentNameLabel?.text = name
    }
}










