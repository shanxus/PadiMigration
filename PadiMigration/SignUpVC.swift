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
import SwiftMessages

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
        
        loginSegment.setTitle("信箱驗證登入", forSegmentAt: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShowing), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDisappear), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTapEndEditing))
        view.addGestureRecognizer(viewTapGesture)
        
        accountTF.delegate = self
        
        setCancelNotInteractable()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loginSegment.selectedSegmentIndex = 1
        loginSegmentTapped(loginSegment)
    }
    
    @IBAction func loginSegmentTapped(_ sender: Any) {
        if let segment = sender as? UISegmentedControl {
            if segment.selectedSegmentIndex == 0 {
                handleEmailVerificationLogin(showComponents: true)
                handleAccountPasswordLogin(showComponents: false)
                
            } else if segment.selectedSegmentIndex == 1 {
                handleEmailVerificationLogin(showComponents: false)
                handleAccountPasswordLogin(showComponents: true)
                cancel.isUserInteractionEnabled = true
                cancel.alpha = 1
                cancel.setTitle("登入", for: .normal)
                continueBtn.setTitle("註冊", for: .normal)
            }
        }
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        if loginSegment.selectedSegmentIndex == 0 {
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
        } else {
            if let account = accountLoginTF.text, account != "", let password = passwordLoginTF.text, password != "" {
                Auth.auth().createUser(withEmail: account, password: password) { (result, error) in
                    if error != nil {
                        if let nsError = error as NSError? {
                            // code is from AuthErrorCode
                            switch nsError.code {
                            case 17007:
                                print("got error: email is already in use...")
                                self.showLoginAlert(title: "錯誤", body: "您所使用的帳號已經被使用")
                            case 17008:
                                print("got error: invalid email...")
                                self.showLoginAlert(title: "錯誤", body: "請使用 email 帳號")
                            case 17026:
                                print("got error: weak password...")
                                self.showLoginAlert(title: "錯誤", body: "請使用安全一點的密碼")
                            default:
                                print("default error handling...")
                                self.showLoginAlert(title: "錯誤", body: "發生未知的錯誤，請再試一次")
                            }
                        }
                    } else {
                        self.login(with: account, password: password)
                    }
                }
            }
        }
    }
    
    func showLoginAlert(title: String, body: String) {
        /* swiftMessage. */
        let msgView = MessageView.viewFromNib(layout: .cardView)
        msgView.button?.removeFromSuperview()
        msgView.configureContent(title: title, body: body)
        msgView.configureTheme(.warning)
        msgView.configureDropShadow()
        SwiftMessages.show(view: msgView)
    }
    
    func login(with account: String, password: String) {
        Auth.auth().signIn(withEmail: account, password: password) { (result, error) in
            if error != nil {
                if let nsError = error as NSError? {
                    switch nsError.code {
                    case 17011:
                        print("got error: user not found...")
                        self.showLoginAlert(title: "錯誤", body: "此帳號未註冊")
                    case 17020:
                        print("got error: network error...")
                        self.showLoginAlert(title: "錯誤", body: "請檢察網路連線")
                    case 17008:
                        print("got error: invalid email...")
                        self.showLoginAlert(title: "錯誤", body: "請使用 email 帳號")
                    case 17009:
                        print("got error: wrong password...")
                        self.showLoginAlert(title: "錯誤", body: "密碼錯誤")
                    default:
                        print("default error handling...", error ?? "")
                        self.showLoginAlert(title: "錯誤", body: "發生未知的錯誤，請再試一次")
                    }
                }
            } else {
                print("login with \(account) successfully...")
                let topVC = GeneralService.findTopVC()
                if let tabView = topVC.storyboard?.instantiateViewController(withIdentifier: "tabView") as? UITabBarController {
                    topVC.present(tabView, animated: true, completion: {
                        if let currentUser = Auth.auth().currentUser {
                            let id = currentUser.uid
                            let email = currentUser.email!
                            let name = email.components(separatedBy: "@").first!
                            GeneralService.createUserInDB(userID: id, email: email, name: name)
                            
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    })
                }
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        if loginSegment.selectedSegmentIndex == 0 {
            detailedInstruction.text = "請使用有效信箱來進行註冊/登入，我們將會寄一封驗證信給您。"
            continueBtn.setTitle("繼續", for: .normal)
            cancel.isUserInteractionEnabled = false
            accountTF.isUserInteractionEnabled = true
        } else {
            if let account = accountLoginTF.text, account != "", let password = passwordLoginTF.text, password != "" {
                login(with: account, password: password)
            }
        }
        
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
            
            continueBtn.setTitle("繼續", for: .normal)
            cancel.setTitle("取消", for: .normal)
            setCancelNotInteractable()
        } else {
            instructionTitle.isUserInteractionEnabled = false
            instructionTitle.alpha = 0
            
            accountTF.isUserInteractionEnabled = false
            accountTF.text = ""
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
            accountInstruction.topAnchor.constraint(equalTo: accountTitle.bottomAnchor, constant: 5).isActive = true
            accountInstruction.translatesAutoresizingMaskIntoConstraints = false
            
            accountLoginTF = UITextField()
            accountLoginTF.autocapitalizationType = .none
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
            passwordTitle.font = UIFont.systemFont(ofSize: 13)
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
            passwordLoginTF.isSecureTextEntry = true
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
            
            accountInstruction.removeFromSuperview()
            accountInstruction = nil
            
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







