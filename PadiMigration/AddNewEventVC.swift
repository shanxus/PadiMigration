//
//  AddNewEventVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/13.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftMessages

enum AddNewEventType: String {
    case addNew = "新增活動"
    case edit = "編輯活動"
}

class AddNewEventVC: UIViewController {

    let headerColor = UIColor(red: 255/255, green: 248/255, blue: 237/255, alpha: 1)
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var eventInfoBlock: UITableView!
    @IBOutlet weak var eventActionBlock: UITableView!
    let addNewEventActionHelper = AddNewEventHelperVC()
    
    @IBOutlet weak var cellHeightConstraint: NSLayoutConstraint!
    var eventNameHolder: String! {
        didSet {
            if let infoBlock = eventInfoBlock {
                infoBlock.reloadData()
            }
        }
    }
    
    var viewType: AddNewEventType? = .addNew
    var userID: String?
    var eventID: String?
    
    @IBOutlet weak var addAction: UIButton!
    var selectedMember: [String] = []
    
    var eventPhotoURL: String?
    var eventPhoto: UIImage? {
        didSet {
            if let infoBlock = eventInfoBlock {
                infoBlock.reloadData()
            }
        }
    }
    var eventPhotoData: Data?
    var eventPhotoHasChanged: Bool?
    
    var eventImgView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let type = viewType {
            viewTitle.text = type.rawValue
            
            let addBtnTitle = type == .addNew ? "新增" : "儲存"
            addAction.setTitle(addBtnTitle, for: .normal)
            
            addNewEventActionHelper.viewType = type
            if let eventID = eventID {
                addNewEventActionHelper.eventID = eventID
            }
        }
                        
        NotificationCenter.default.addObserver(self, selector: #selector(AddNewEventVC.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        eventInfoBlock.dataSource = self
        eventInfoBlock.delegate = self
        eventInfoBlock.tableFooterView = UIView()
        eventInfoBlock.isScrollEnabled = false
        
        handleGenerateDummyEventImage()
        
        /* pass the members that had already been selected. */
        if selectedMember.count != 0 {
            addNewEventActionHelper.selectedMember = selectedMember
        }
        
        eventActionBlock.backgroundColor = headerColor
        eventActionBlock.dataSource = addNewEventActionHelper
        eventActionBlock.delegate = addNewEventActionHelper
        addNewEventActionHelper.passSelectedMemberDelegate = self
        
    }
    
    @IBAction func dismissAddNewEventView(_ sender: Any) {
        
        // add a alert (like you will lost data) before dismissing.
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addBtnTapped(_ sender: Any) {
        guard let type = viewType else {return}
        let topVC = GeneralService.findTopVC()
        if eventNameHolder == "" || eventNameHolder == "請輸入活動名稱" {
            let alert = UIAlertController(title: "小提醒", message: "請記得設定活動名稱", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
            
            topVC.present(alert, animated: true, completion: nil)
            return
        }
        
        if type == .addNew {
            if eventPhoto == nil {
                let alert = UIAlertController(title: "小提醒", message: "請記得設定活動照片", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(ok)
                
                topVC.present(alert, animated: true, completion: nil)
                return
            }
            
            guard let img = eventPhoto else { return }
            let newUUID = UUID().uuidString
            
            EntityHelperClass.upload(image: img, fileName: newUUID) { (imageDownloadURL) in
                
                /* create new event obj. */
                let time = EntityHelperClass.getDateNow()
                let newEvent = PadiEvent(withName: self.eventNameHolder, ID: newUUID, imageURL: imageDownloadURL, date: time, isFavorite: false, payCollection: [], memberList: self.selectedMember)
                
                /* store new event obj to firebase */
                let storeEventHelper = ExamplePadiEvent()
                guard let userID = Auth.auth().currentUser?.uid else {return}
                storeEventHelper.storeIntoDB(event: newEvent, userID: userID)
                
            }
        } else if type == .edit {
            guard let user = userID, let event = eventID else {return}
            let helper = ExamplePadiEvent()
            
            /* store new event image. */
            if let _ = eventPhotoHasChanged {
                let imageHelper = GeneralService()
                if let data = eventPhotoData {
                    imageHelper.upload(image: data, uuid: event, path: DBPathStrings.payImagePath) { (downloadURL: String) in
                        helper.store(imgURL: downloadURL, eventID: event, userID: user)
                    }
                }
            }
            
            /* store new event name. */
            if let newEventName = eventNameHolder {
                helper.store(name: newEventName, eventID: event, userID: user)
            }
            
            let soretedMemberList = selectedMember.sorted()
            helper.store(members: soretedMemberList, eventID: event, userID: user)
        }
        
        self.dismiss(animated: true, completion: {
            if type == .addNew {
                /* swiftMessage. */
                let msgView = MessageView.viewFromNib(layout: .cardView)
                msgView.button?.removeFromSuperview()
                msgView.configureContent(title: "新增活動成功", body: "您新增了一筆分款活動")
                msgView.configureTheme(.success)
                msgView.configureDropShadow()
                SwiftMessages.show(view: msgView)
            } else if type == .edit {
                /* swiftMessage. */
                let msgView = MessageView.viewFromNib(layout: .cardView)
                msgView.button?.removeFromSuperview()
                msgView.configureContent(title: "修改活動成功", body: "您修改了一筆分款活動")
                msgView.configureTheme(.success)
                msgView.configureDropShadow()
                SwiftMessages.show(view: msgView)
            }
        })
    }
    
    @objc func rotated() {
        handleGenerateDummyEventImage()
    }
    
    func handleGenerateDummyEventImage() {
        
        guard let thisTableView = eventInfoBlock else {return}
        let imgIndex = IndexPath(row: 0, section: 0)
        guard let cell = thisTableView.cellForRow(at: imgIndex) as? AddNewEventInfoBlockTVC else {return}
        if let imgView = cell.eventImage {
            eventImgView = imgView
            let frame = imgView.frame
            
            let dummyImgView = UIView(frame: frame)
            dummyImgView.isUserInteractionEnabled = true
            dummyImgView.backgroundColor = UIColor.clear
            dummyImgView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChangeEventPhoto)))
            cell.addSubview(dummyImgView)
        }
    }
    
    @objc func handleChangeEventPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let actionSheet = UIAlertController(title: "編輯款項照片", message: "請選擇照片來源", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "相機", style: .default, handler: { (action:UIAlertAction) in
           
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                print("Camera is not available")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "相片圖庫", style: .default, handler: { (action:UIAlertAction) in
           imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .destructive, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
}

extension AddNewEventVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventInfoBlock", for: indexPath) as! AddNewEventInfoBlockTVC
        
        guard let type = viewType else { return cell }
        
        if type == .addNew {
            if let name = eventNameHolder {
                cell.eventName.text = name
            }
            
            if let _ = eventPhotoHasChanged {
                cell.eventImage.image = eventPhoto
            } else {
                cell.eventImage.image = #imageLiteral(resourceName: "PadiEventDefault")
            }
            
        } else if type == .edit {
            if let name = eventNameHolder {
                cell.eventName.text = name
            }
            
            if let url = eventPhotoURL, eventPhotoHasChanged == nil {
                let imgURL = URL(string: url)
                cell.eventImage.kf.setImage(with: imgURL)
            } else if let _ = eventPhotoHasChanged {
                cell.eventImage.image = eventPhoto
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        // dynamically change the height for the cell.
        let cellHight = cell.bounds.height
        cellHeightConstraint.constant = cellHight
    }
    
}

extension AddNewEventVC: UITableViewDelegate {
 
    func handleGenerateEventIntoChangeAlert() {
        if let showEditTxtFieldVC = self.storyboard?.instantiateViewController(withIdentifier: "showEditTxtFieldVC") as? ShowEditTxtFieldVC {
            
            let txtInfo = EditTxtInfo(flag: Flag.addEventName.rawValue, titleTxt: "編輯活動名稱", inputTxt: self.eventNameHolder, actionTxt: "儲存")
            showEditTxtFieldVC.viewTxtPrepare = txtInfo
            showEditTxtFieldVC.passEventNameDelegate = self
            self.present(showEditTxtFieldVC, animated:true, completion:nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            handleGenerateEventIntoChangeAlert()
        }
    }
}

extension AddNewEventVC: PassEventNameBack {
    func passEventName(event name: String) {
        self.eventNameHolder = name
    }
}

extension AddNewEventVC: PassSelectedMemberback {
    func passSelectedMember(member: [String]) {
        self.selectedMember = member
    }
}

extension AddNewEventVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        guard let resizedImg = UIImageJPEGRepresentation(image, 0.3) else {return}
        print("new image size: ", resizedImg.count)
        
        eventPhoto = UIImage(data: resizedImg)
        eventPhotoHasChanged = true
        eventPhotoData = resizedImg
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}






