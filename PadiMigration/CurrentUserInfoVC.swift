//
//  CurrentUserInfoVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/26.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Instructions
import SkeletonView

class CurrentUserInfoVC: UIViewController {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var signOutBtn: UIButton!
    
    var userID: String?
    var isUserImageChanged: Bool = false
    var selectedImageData: Data?
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    @IBOutlet weak var editButton: UIButton!
    
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUserbasicInfo()
        
        let tapUserImage = UITapGestureRecognizer(target: self, action: #selector(userImageTapped))
        userImage.addGestureRecognizer(tapUserImage)
        let tapUserName = UITapGestureRecognizer(target: self, action: #selector(userNameTapped))
        userName.addGestureRecognizer(tapUserName)
        
        enableSignOutBtnCheck()
        
        self.coachMarksController.dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let finishShowingInstructions = UserDefaults.standard.bool(forKey: InstructionControlling.showInstrInCurrentUserInfoVCFinished)
        if finishShowingInstructions == false {
            self.coachMarksController.start(on: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.coachMarksController.stop(immediately: true)
    }
    
    @IBAction func dimissTapped(_ sender: Any) {
        if editButton.titleLabel?.text == "儲存" {
            return
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            
            let topVC = GeneralService.findTopVC()
            if let loginVC = topVC.storyboard?.instantiateViewController(withIdentifier: "SignUpVC") as? SignUpVC {
                topVC.present(loginVC, animated: true, completion: nil)
            }
            
        } catch {
            print("error when sign out...")
        }
    }
    
    @IBAction func editTapped(_ sender: Any) {
        if editButton.titleLabel?.text == "編輯" {
            editButton.setTitle("儲存", for: .normal)
            
            showEditReminder()
            
        } else if editButton.titleLabel?.text == "儲存" {
            guard let user = userID else {return}
            editButton.setTitle("編輯", for: .normal)
            
            userImage.isUserInteractionEnabled = false
            userName.isUserInteractionEnabled = false
            
            let helper = ExamplePadiMember()
            if isUserImageChanged == true {
                let imageHelper = GeneralService()
                if let data = selectedImageData {
                    imageHelper.upload(image: data, uuid: user, path: DBPathStrings.userImagePath) { (downloadURL) in
                        helper.store(imageURL: downloadURL, userID: user)
                        self.isUserImageChanged = false
                    }
                }
            }
            if let name = userName.text {
                helper.store(userName: name, userID: user)
            }
        }
    }
    
    @objc func userImageTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        let topVC = GeneralService.findTopVC()
        let alert = UIAlertController(title: "編輯圖片", message: "請選擇圖片來源", preferredStyle: .actionSheet)
        let fromPhotoLibrary = UIAlertAction(title: "照片圖庫", style: .default) { (action) in
            imagePicker.sourceType = .photoLibrary
            topVC.present(imagePicker, animated: true, completion: nil)
        }
        let fromCamera = UIAlertAction(title: "相機", style: .default) { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                topVC.present(imagePicker, animated: true, completion: nil)
            }
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alert.addAction(fromPhotoLibrary)
        alert.addAction(fromCamera)
        alert.addAction(cancel)
        topVC.present(alert, animated: true, completion: nil)
    }
    
    @objc func userNameTapped() {
        let alert = UIAlertController(title: "編輯名稱", message: "請輸入新的使用者名稱", preferredStyle: .alert)
        alert.addTextField { (tf) in
            if let txt = self.userName.text {
                tf.placeholder = txt
            }
        }
        let ok = UIAlertAction(title: "OK", style: .default) { (action) in
            if let tf = alert.textFields?.first {
                if let txt = tf.text, txt != "" {
                    self.userName.text = txt
                }
            }
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
            
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }
    
    func enableSignOutBtnCheck() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        if let userID = userID {
            if currentUserID != userID {
                signOutBtn.isUserInteractionEnabled = false
                signOutBtn.layer.opacity = 0.0
            }
        }
    }
    
    func showEditReminder() {
        let alert = UIAlertController(title: "提醒", message: "您現在可以透過點擊圖片以及名稱來編輯它們", preferredStyle: .alert)
        let ok = UIAlertAction(title: "知道了", style: .default) { (action) in
            self.userImage.isUserInteractionEnabled = true
            self.userName.isUserInteractionEnabled = true
        }
        alert.addAction(ok)
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }
    
    func setUserbasicInfo() {
        
        if let _ = Auth.auth().currentUser {
            loadUserEmail()
            loadUserName()
            loadUserImage()
        }
    }
    
    func handleShowUserNameAlert() {
        let alert = UIAlertController(title: "使用者暱稱", message: "請輸入使用者暱稱，您的朋友將會看到您的暱稱", preferredStyle: .alert)
        alert.addTextField { (tf) in
            tf.placeholder = "綠皮卡"
        }
        let sure = UIAlertAction(title: "確定", style: .default) { (action) in
            if let tf = alert.textFields?.first {
                if let txt = tf.text {
                    if txt != "" {
                        print("name is set: ", txt)
                        self.userName.text = txt
                    }
                }
            }
        }
        alert.addAction(sure)
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }
    
    func loadUserImage() {
        guard let user = userID else {return}
        let helper = ExamplePadiMember()
        
        userImage.isSkeletonable = true
        userImage.showAnimatedGradientSkeleton()
        helper.fetchUserImageURL(userID: user) { (url: String) in
            let imageURL = URL(string: url)
            DispatchQueue.main.async {
                self.userImage.kf.setImage(with: imageURL)
                self.userImage.hideSkeleton()
            }
        }
    }

    func loadUserName() {
        guard let user = userID else {return}
        let helper = ExamplePadiMember()
        userName.isSkeletonable = true
        userName.showAnimatedGradientSkeleton()
        helper.fetchName(userID: user) { (name: String) in
            DispatchQueue.main.async {
                self.userName.text = name
                self.userName.hideSkeleton()
            }
        }
    }
    
    func loadUserEmail() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        if let userID = userID {
            
            if userID != currentUserID {
                userEmail.text = "自定義使用者"
            } else {
                if let currentUser = Auth.auth().currentUser {
                    if let email = currentUser.email {
                        userEmail.text = email
                    }
                }
            }
        }
    }
}

extension CurrentUserInfoVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImg = info[UIImagePickerControllerOriginalImage] as! UIImage
        guard let resizedImg = UIImageJPEGRepresentation(selectedImg, 0.3) else {
            picker.dismiss(animated: true, completion: nil)
            return
        }
        selectedImageData = resizedImg
        userImage.image = selectedImg
        picker.dismiss(animated: true, completion: {
            self.isUserImageChanged = true
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension CurrentUserInfoVC: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 2
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        if index == 0 {
            return coachMarksController.helper.makeCoachMark(for: editButton)
        } else {
            return coachMarksController.helper.makeCoachMark(for: signOutBtn)
        }
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        if index == 0 {
            coachViews.bodyView.hintLabel.text = "點擊編輯鈕後，點擊頭像或使用者名稱來編輯"
            coachViews.bodyView.nextLabel.text = "Ok!"
        } else if index == 1 {
            coachViews.bodyView.hintLabel.text = "點擊登出會登出目前使用帳號"
            coachViews.bodyView.nextLabel.text = "Ok!"
            UserDefaults.standard.set(true, forKey: InstructionControlling.showInstrInCurrentUserInfoVCFinished)            
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}












