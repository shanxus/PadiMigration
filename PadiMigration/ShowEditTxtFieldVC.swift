//
//  EditEventNameVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/17.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseAuth

enum Flag: String {
    case findPadiUser = "findPadiUser"
    case addEventName = "addEventName"
    case changeEventName = "changeEventName"
}

/* prepare for displaying different txt. */
class EditTxtInfo {
    var flag: Flag?
    var titleTxt: String?
    var inputFieldTxt: String?
    var actionBtnTitleTxt: String?
    init(flag: String = "", titleTxt: String = "", inputTxt: String = "", actionTxt: String = "") {
        self.flag = Flag(rawValue: flag)
        self.titleTxt = titleTxt
        self.inputFieldTxt = inputTxt
        self.actionBtnTitleTxt = actionTxt
    }
}

class ShowEditTxtFieldVC: UIViewController {

    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var textNumberIndicator: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var indicatorTrailingContraint: NSLayoutConstraint!
    
    var viewTxtPrepare = EditTxtInfo()
    
    var passEventNameDelegate: PassEventNameBack?
    
    var searchResultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handleInputFieldTxt()
        handleViewTitleTxt()
        handleActionBtnTxt()
        handleTxtCountIndicator()
        
        self.hideKeyboardWhenTappedAround()
        self.inputField.delegate = self
        
        createSearchResultLabel()
        
        inputField.becomeFirstResponder()
    }
    
    func createSearchResultLabel() {
        searchResultLabel = UILabel()
        searchResultLabel.font = UIFont.boldSystemFont(ofSize: 15)
        searchResultLabel.numberOfLines = 0
        view.addSubview(searchResultLabel)
        searchResultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        searchResultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        searchResultLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 30).isActive = true
        searchResultLabel.heightAnchor.constraint(equalToConstant: 50)
        searchResultLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func handleInputFieldTxt() {
        if let txt = viewTxtPrepare.inputFieldTxt {
            inputField.text = txt
        }
    }
    
    func handleViewTitleTxt() {
        if let titleTxt = viewTxtPrepare.titleTxt {
            viewTitle.text = titleTxt
        }
    }
    
    func handleActionBtnTxt() {
        if let txt = viewTxtPrepare.actionBtnTitleTxt {
            actionButton.setTitle(txt, for: .normal)
        }
    }
    
    func handleTxtCountIndicator() {
        // think about how to use the indicator label later.
        indicatorTrailingContraint.constant = (self.view.bounds.width - inputField.bounds.width)/2
        textNumberIndicator.text = ""
    }

    @IBAction func dismissEditEventNameView(_ sender: Any) {
        // add a alert before dismissing.
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func actionBtnTapped(_ sender: Any) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        if let flag = viewTxtPrepare.flag?.rawValue {
            switch flag {
            case Flag.findPadiUser.rawValue:
                if let txt = inputField.text {                    
                    let helper = ExampleMainUser.shareInstance
                    helper.findUser(withAccount: txt, completion: { (result, data) in
                        if result == false {
                            self.searchResultLabel.text = "沒有搜尋到 \(txt) 該使用者。"
                        } else {
                            self.inputField.text = ""
                            self.searchResultLabel.text = "成功搜尋到 \(txt) 該使用者，並已加入您的好友清單。"
                        }
                        helper.addUserAsFriend(userID: currentUserID, result: result, friend: data)
                    })
                }
            case Flag.addEventName.rawValue:                
                if let eventName = inputField.text {
                    passEventNameDelegate?.passEventName(event: eventName)
                    dismissEditEventNameView(self)
                }
            default:
                break
            }
        }
    }

    @IBAction func saveEditNameAction(_ sender: Any) {
        
    }
}

extension ShowEditTxtFieldVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension String {
    // 是否含有中文字元
    func isContainsChineseCharacters() -> Bool {
        for scalar in self.unicodeScalars {
            if scalar.value >= 19968 && scalar.value <= 171941 {
                return true
            }
        }
        return false
    }
}




