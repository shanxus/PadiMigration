//
//  AddNewSelfDefinedFriendVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/29.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class AddNewSelfDefinedFriendVC: UIViewController {
    @IBOutlet weak var friendImage: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    
    var selectedImageData: Data?
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let data = UIImageJPEGRepresentation(#imageLiteral(resourceName: "PadifriendDefault"), 1.0) as Data? {
            selectedImageData = data
        }
        
        friendImage.isUserInteractionEnabled = true
        friendName.isUserInteractionEnabled = true
        
        let imageTapped = UITapGestureRecognizer(target: self, action: #selector(handleSelectUserImage))
        friendImage.addGestureRecognizer(imageTapped)
        let nameTapped = UITapGestureRecognizer(target: self, action: #selector(handleEditingUserName))
        friendName.addGestureRecognizer(nameTapped)
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        if friendName.text == "好友名稱" {
            return
        }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        
        guard let imageData = selectedImageData else {return}
        guard let name = friendName.text else {return}
        
        let uuid = UUID().uuidString
        let memberHelper = ExamplePadiMember()
        let imageHelper = GeneralService()
        imageHelper.upload(image: imageData, uuid: uuid, path: DBPathStrings.userImagePath) { (url) in
            memberHelper.storeSelfDefinedMember(memberID: uuid, imgURL: url, memberName: name)
            
            let friendTargetRef = self.ref.child(DBPathStrings.friendDataPath).child(currentUserID).child(uuid)
            friendTargetRef.setValue(["\(DBPathStrings.friendTypePath)":DBPathStrings.selfDefined])
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func handleSelectUserImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let topVC = GeneralService.findTopVC()
        
        let alert = UIAlertController(title: "更改朋友圖片", message: "請選擇圖片來源，或者繼續使用預設圖片", preferredStyle: .actionSheet)
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
            
        }
        let cancel = UIAlertAction(title: "取消", style: .destructive) { (action) in
            
        }
        alert.addAction(fromPhotoLibrary)
        alert.addAction(fromCamera)
        alert.addAction(fromDefault)
        alert.addAction(cancel)
        
        topVC.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleEditingUserName() {
        let alert = UIAlertController(title: "好友名稱", message: "請輸入自定義好友的名稱", preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = self.friendName.text
        }
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            if let tf = alert.textFields?.first {
                if let txt = tf.text {
                    if txt != "" {
                        self.friendName.text = txt
                    }
                }
            }
        }
        alert.addAction(ok)
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }

}

extension AddNewSelfDefinedFriendVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImg = info[UIImagePickerControllerOriginalImage] as! UIImage
        guard let resizedImg = UIImageJPEGRepresentation(selectedImg, 0.3) else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        
        selectedImageData = resizedImg
        friendImage.image = selectedImg
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}





