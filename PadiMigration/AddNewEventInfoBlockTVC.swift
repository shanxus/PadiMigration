//
//  eventInfoBlockTVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/13.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class AddNewEventInfoBlockTVC: UITableViewCell {

    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var eventName: UILabel!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    weak var passImageDelegate: PassSelectedImage?
    
    override func awakeFromNib() {
        print("awake...")
        
        eventImage.isUserInteractionEnabled = true
        let tapImage = UITapGestureRecognizer(target: self, action: #selector(handleImageCellTapped))
        eventImage.addGestureRecognizer(tapImage)
        
        eventName.isUserInteractionEnabled = true
        let tapName = UITapGestureRecognizer(target: self, action: #selector(handleNameCellTapped))
        eventName.addGestureRecognizer(tapName)
    }
    
    @objc func handleImageCellTapped() {
        handleChangeEventPhoto()
    }
    
    @objc func handleNameCellTapped() {
        
    }
    
    /*
    func handleGenerateEventIntoChangeAlert() {
        let topVC = GeneralService.findTopVC()
        if let showEditTxtFieldVC = topVC.storyboard?.instantiateViewController(withIdentifier: "showEditTxtFieldVC") as? ShowEditTxtFieldVC {
            
            let txtInfo = EditTxtInfo(flag: Flag.addEventName.rawValue, titleTxt: "編輯活動名稱", inputTxt: self.eventNameHolder, actionTxt: "儲存")
            showEditTxtFieldVC.viewTxtPrepare = txtInfo
            showEditTxtFieldVC.passEventNameDelegate = self
            let topVC = GeneralService.findTopVC()
            topVC.present(showEditTxtFieldVC, animated: true, completion: nil)
        }
    }
    */
    
    func handleChangeEventPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let topVC = GeneralService.findTopVC()
        
        let actionSheet = UIAlertController(title: "編輯款項照片", message: "請選擇照片來源", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "相機", style: .default, handler: { (action:UIAlertAction) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                topVC.present(imagePicker, animated: true, completion: nil)
            } else {
                print("Camera is not available")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "相片圖庫", style: .default, handler: { (action:UIAlertAction) in
            imagePicker.sourceType = .photoLibrary
            topVC.present(imagePicker, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .destructive, handler: nil))
        topVC.present(actionSheet, animated: true, completion: nil)
    }
}

extension AddNewEventInfoBlockTVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        guard let resizedImg = UIImageJPEGRepresentation(image, 0.3) else {return}
        print("new image size: ", resizedImg.count)
        passImageDelegate?.pass(withImageData: resizedImg)
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}




