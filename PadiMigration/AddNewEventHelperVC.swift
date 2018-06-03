//
//  AddNewEventHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/13.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class AddNewEventHelperVC: UIViewController {

    let headerColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
    
    var viewType: AddNewEventType?
    var selectedMember: [String] = []
    var passSelectedMemberDelegate: PassSelectedMemberback?
    
    /* this variable is used when user wants to add a new pay in the editing event mode. */
    var eventID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension AddNewEventHelperVC: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return 1
        } else if section == 2 {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "eventActionBlock", for: indexPath) as? AddNewEventActionTVC {
            
            cell.indicatorLabel.text = ">"
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell.actionTitle.text = "新增活動成員"
                    return cell
                }
            } else if indexPath.section == 1{
                if let type = viewType {
                    if type == .addNew {
                        cell.actionTitle.layer.opacity = 0.5
                        cell.isUserInteractionEnabled = false
                    } else if type == .edit {
                        cell.actionTitle.layer.opacity = 1.0
                        cell.isUserInteractionEnabled = true
                    }
                }
                if indexPath.row == 0 {
                    cell.actionTitle.text = "新增款項"
                    return cell
                }
            } else if indexPath.section == 2 {
                if let type = viewType {
                    if type == .addNew {
                        cell.actionTitle.layer.opacity = 0.5
                        cell.isUserInteractionEnabled = false
                    } else if type == .edit {
                        cell.actionTitle.layer.opacity = 0.5
                        cell.isUserInteractionEnabled = false
                    }
                }
                cell.actionTitle.text = "可編輯成員"
                return cell
            } else {
                cell.actionTitle.layer.opacity = 0.5
                cell.isUserInteractionEnabled = false
                cell.actionTitle.text = "公開此活動"
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 3 {
            return 50
        } else {
            return 0
        }        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = headerColor
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = headerColor
        return headerView
    }
}

extension AddNewEventHelperVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            
            let topVC = GeneralService.findTopVC()
            if let friendListVC = topVC.storyboard?.instantiateViewController(withIdentifier: "myFriendOverviewVC") as? MyFriendOverviewVC {
                friendListVC.friendVCType = FriendsVCType.eventFriendList
                friendListVC.selected = selectedMember
                friendListVC.selectedMembersDelegate = self
                let displayInfo = friendOverviewInfo(titleTxt: "選擇活動成員", actionTxt: "儲存")
                friendListVC.prepareDisplaying = displayInfo
                topVC.present(friendListVC, animated:true, completion:nil)
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let topVC = GeneralService.findTopVC()
                if let addNewPaymentVC = topVC.storyboard?.instantiateViewController(withIdentifier: "addNewPaymentVC") as? AddNewPaymentVC {
                    if let eventID = eventID {
                        addNewPaymentVC.belongsToEventID = eventID
                        topVC.present(addNewPaymentVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

extension AddNewEventHelperVC: PassSelectedMemberback {
    func passSelectedMember(member: [String]) {
        self.selectedMember = member
        self.passSelectedMemberDelegate?.passSelectedMember(member: self.selectedMember)
    }    
}








