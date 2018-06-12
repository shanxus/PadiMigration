//
//  AddNewFriendVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/15.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class AddNewFriendVC: UIViewController {

    let headerColor = UIColor(red: 255/255, green: 248/255, blue: 237/255, alpha: 1)
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var actionBlockTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        actionBlockTableView.dataSource = self
        actionBlockTableView.delegate = self
        actionBlockTableView.tableFooterView = UIView()
        actionBlockTableView.backgroundColor = headerColor
    }

    @IBAction func dismissAddNewFriendView(_ sender: Any) {
        // add a alert before dismissing.
        self.dismiss(animated: true, completion: nil)
    }
}

extension AddNewFriendVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AddNewFriendTVC", for: indexPath) as? AddNewFriendTVC {
            
            cell.indicatorLabel.text = ""
            if indexPath.row == 0 {
                cell.actionTitle.text = "搜尋Padi帳號"
                return cell
            } else {
                cell.actionTitle.text = "建立自定義好友"
                return cell
            }
            
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = headerColor
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = headerColor
        if section == 0 {
            var actionDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-20, height: 10))
                descriptionLabel.text = "選擇以Padi帳號建立時，可以讓您與朋友建立共同的活動，並即時分享款項資訊。\n\n選擇建立自定義好友的情況為對方沒有Padi帳號，或您欲依照自己喜好定義好友。"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(actionDescription)
            return footerView
        } else {
            return footerView
        }
    }
}

extension AddNewFriendVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let topVC = GeneralService.findTopVC()
        if indexPath.row == 0 {
            if let showEditTxtFieldVC = topVC.storyboard?.instantiateViewController(withIdentifier: "showEditTxtFieldVC") as? ShowEditTxtFieldVC {
                let txtInfo = EditTxtInfo(flag: Flag.findPadiUser.rawValue, titleTxt: "搜尋padi使用者", inputTxt: "", actionTxt: "搜尋")
                showEditTxtFieldVC.viewTxtPrepare = txtInfo
                topVC.present(showEditTxtFieldVC, animated:true, completion:nil)
            }
        } else {
            if let selfDefinedFriendVC = topVC.storyboard?.instantiateViewController(withIdentifier: "AddNewSelfDefinedFriendVC") as? AddNewSelfDefinedFriendVC {
                topVC.present(selfDefinedFriendVC, animated: true, completion: nil)
            }
        }
    }
}





