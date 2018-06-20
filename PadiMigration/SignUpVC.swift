//
//  SignUpVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/25.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDynamicLinks
import FirebaseAuth

class SignUpVC: UIViewController {
    @IBOutlet weak var accountTF: UITextField!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var instructionTitle: UILabel!
    @IBOutlet weak var detailedInstruction: UILabel!
    
    var isViewMovingUp: Bool = false
    var keyboardHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowing), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTapEndEditing))
        view.addGestureRecognizer(viewTapGesture)
        
        accountTF.delegate = self
        
        setCancelNotInteractable()
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        guard let account = accountTF.text else {
            print("info not enough")
            return
        }
        print("got txt: ", account)
        guard let trimmedAccount = account.components(separatedBy: " ").first else {return}
        view.endEditing(true)
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://www.example.com")
        // The sign-in operation has to always be completed in the app.
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        Auth.auth().sendSignInLink(toEmail: trimmedAccount, actionCodeSettings: actionCodeSettings) { error in
            // ...
            if let error = error {
                print(error.localizedDescription)
                return
            }
            // The link was successfully sent. Inform the user.
            // Save the email locally so you don't need to ask the user for it again
            // if they open the link on the same device.
            UserDefaults.standard.set(trimmedAccount, forKey: "Email")
            print("Check your email for link")
            // ...
            
            self.handleShowingEmailHasSent()
            
        }
        
    }
    @IBAction func cancelTapped(_ sender: Any) {
        detailedInstruction.text = "請使用有效信箱來進行註冊/登入，我們將會寄一封驗證信給您。"
        continueBtn.setTitle("繼續", for: .normal)
        cancel.isUserInteractionEnabled = false
        accountTF.isUserInteractionEnabled = true
    }
    
    @objc func handleViewTapEndEditing(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func handleKeyboardShowing(notification: NSNotification) {
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        if let keyboardFrame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? CGRect {
            //print("frame: ", keyboardFrame)
            print("showing frame.height: ", keyboardFrame.height)
            if isViewMovingUp == false {
                isViewMovingUp = true
                keyboardHeight = keyboardFrame.height
                UIView.animate(withDuration: duration+1.0) {
                    self.view.center.y -= keyboardFrame.height
                }
            }
        }
    }
    
    @objc func handleKeyboardDisappear(notification: NSNotification) {
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        if let keyboardFrame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? CGRect {
            //print("frame: ", keyboardFrame)
            print("disa frame.height: ", keyboardFrame.height)
            if isViewMovingUp == true {
                UIView.animate(withDuration: duration/2, animations: {
                    self.view.center.y += self.keyboardHeight
                }) { (true) in
                    self.isViewMovingUp = false
                }
            }
        }
    }
    
    func handleShowingEmailHasSent() {
        accountTF.isUserInteractionEnabled = true
        cancel.alpha = 1.0
        self.detailedInstruction.text = "我們已經寄驗證信到您的信箱，請透過信內提及的連結來登入Padi。"
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.05, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: {
            self.detailedInstruction.center.x -= 100
        }) { (true) in
            
        }
        accountTF.isUserInteractionEnabled = false
        
        continueBtn.setTitle("重寄", for: .normal)
        cancel.isUserInteractionEnabled = true
    }
    
    func setCancelNotInteractable() {
        cancel.isUserInteractionEnabled = false
        cancel.alpha = 0.5
    }
}

extension SignUpVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}







