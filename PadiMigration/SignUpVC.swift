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
    @IBOutlet weak var loginSegment: UISegmentedControl!
    
    /* components below are for the account/password login. */
    var accountTitle: UILabel!
    var accountLoginTF: UITextField!
    var passwordTitle: UILabel!
    var passwordLoginTF: UITextField!
    var accountInstruction: UILabel!
    
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
    
    @IBAction func loginSegmentTapped(_ sender: Any) {
        if let segment = sender as? UISegmentedControl {
            if segment.selectedSegmentIndex == 0 {
                handleEmailVerificationLogin(showComponents: true)
                handleAccountPasswordLogin(showComponents: false)
            } else if segment.selectedSegmentIndex == 1 {
                handleEmailVerificationLogin(showComponents: false)
                handleAccountPasswordLogin(showComponents: true)
            }
        }
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
        /* redesign the alert animation.
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.05, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: {
            self.detailedInstruction.center.x -= 100
        }) { (true) in
            
        }
        */
        accountTF.isUserInteractionEnabled = false
        
        continueBtn.setTitle("重寄", for: .normal)
        cancel.isUserInteractionEnabled = true
    }
    
    func setCancelNotInteractable() {
        cancel.isUserInteractionEnabled = false
        cancel.alpha = 0.5
    }
    
    func handleEmailVerificationLogin(showComponents show: Bool) {
        if show == true {
            instructionTitle.isUserInteractionEnabled = false
            instructionTitle.alpha = 1
            
            accountTF.isUserInteractionEnabled = true
            accountTF.alpha = 1
            
            detailedInstruction.isUserInteractionEnabled = false
            detailedInstruction.alpha = 1
        } else {
            instructionTitle.isUserInteractionEnabled = false
            instructionTitle.alpha = 0
            
            accountTF.isUserInteractionEnabled = false
            accountTF.resignFirstResponder()
            accountTF.alpha = 0
            
            detailedInstruction.isUserInteractionEnabled = false
            detailedInstruction.alpha = 0
        }
    }
    
    func handleAccountPasswordLogin(showComponents show: Bool) {
        
        if show == true {
            accountTitle = UILabel()
            accountTitle.text = "帳號:"
            accountTitle.font = UIFont.systemFont(ofSize: 15)
            accountTitle.textAlignment = .left
            
            view.addSubview(accountTitle)
            accountTitle.leadingAnchor.constraint(equalTo: loginSegment.leadingAnchor, constant: 10).isActive = true
            accountTitle.trailingAnchor.constraint(equalTo: loginSegment.trailingAnchor, constant: 0).isActive = true
            accountTitle.topAnchor.constraint(equalTo: loginSegment.bottomAnchor, constant: 40).isActive = true
            accountTitle.translatesAutoresizingMaskIntoConstraints = false
            
            accountInstruction = UILabel()
            accountInstruction.text = "請使用您的 email 帳號來作為 Padi 帳號。"
            accountInstruction.textAlignment = .left
            accountInstruction.textColor = UIColor.darkGray
            accountInstruction.font = UIFont.systemFont(ofSize: 13)
            
            view.addSubview(accountInstruction)
            accountInstruction.leadingAnchor.constraint(equalTo: accountTitle.leadingAnchor, constant: 0).isActive = true
            accountInstruction.trailingAnchor.constraint(equalTo: accountTitle.trailingAnchor, constant: 0).isActive = true
            accountInstruction.topAnchor.constraint(equalTo: accountTitle.bottomAnchor, constant: 0).isActive = true
            accountInstruction.translatesAutoresizingMaskIntoConstraints = false
            
            accountLoginTF = UITextField()
            accountLoginTF.placeholder = "yourEmailAccount@gmail.com"
            accountLoginTF.font = UIFont.systemFont(ofSize: 13)
            accountLoginTF.borderStyle = .roundedRect
            accountLoginTF.backgroundColor = UIColor(red: 243/255, green: 237/255, blue: 228/255, alpha: 1)
            
            view.addSubview(accountLoginTF)
            accountLoginTF.topAnchor.constraint(equalTo: accountInstruction.bottomAnchor, constant: 0).isActive = true
            accountLoginTF.leadingAnchor.constraint(equalTo: accountTitle.leadingAnchor, constant: 0).isActive = true
            accountLoginTF.trailingAnchor.constraint(equalTo: accountTitle.trailingAnchor, constant: 0).isActive = true
            accountLoginTF.heightAnchor.constraint(equalToConstant: 30).isActive = true
            accountLoginTF.translatesAutoresizingMaskIntoConstraints = false
            
            passwordTitle = UILabel()
            passwordTitle.text = "密碼:"
            passwordTitle.font = UIFont.systemFont(ofSize: 17)
            passwordTitle.textAlignment = .left
            
            view.addSubview(passwordTitle)
            passwordTitle.leadingAnchor.constraint(equalTo: loginSegment.leadingAnchor, constant: 10).isActive = true
            passwordTitle.trailingAnchor.constraint(equalTo: loginSegment.trailingAnchor, constant: 0).isActive = true
            passwordTitle.topAnchor.constraint(equalTo: accountLoginTF.bottomAnchor, constant: 20).isActive = true
            passwordTitle.translatesAutoresizingMaskIntoConstraints = false
            
            passwordLoginTF = UITextField()
            passwordLoginTF.placeholder = "your password"
            passwordLoginTF.font = UIFont.systemFont(ofSize: 13)
            passwordLoginTF.borderStyle = .roundedRect
            passwordLoginTF.backgroundColor = UIColor(red: 243/255, green: 237/255, blue: 228/255, alpha: 1)
            
            view.addSubview(passwordLoginTF)
            passwordLoginTF.topAnchor.constraint(equalTo: passwordTitle.bottomAnchor, constant: 5).isActive = true
            passwordLoginTF.leadingAnchor.constraint(equalTo: passwordTitle.leadingAnchor, constant: 0).isActive = true
            passwordLoginTF.trailingAnchor.constraint(equalTo: passwordTitle.trailingAnchor, constant: 0).isActive = true
            passwordLoginTF.heightAnchor.constraint(equalToConstant: 30).isActive = true
            passwordLoginTF.translatesAutoresizingMaskIntoConstraints = false
            
        } else {
            accountTitle.removeFromSuperview()
            accountTitle = nil
            
            accountLoginTF.removeFromSuperview()
            accountLoginTF = nil
            
            passwordTitle.removeFromSuperview()
            passwordTitle = nil
            
            passwordLoginTF.removeFromSuperview()
            passwordLoginTF = nil
        }
    }
}

extension SignUpVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}







