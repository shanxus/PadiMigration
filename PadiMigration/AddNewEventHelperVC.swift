//
//  AddNewEventHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/13.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class AddNewEventHelperVC: UIViewController {

    let headerColor = UIColor(red: 255/255, green: 248/255, blue: 237/255, alpha: 1)
    
    var viewType: AddNewEventType?
    var selectedMember: [String] = []
    weak var passSelectedMemberDelegate: PassSelectedMemberback?
    
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
            return 0
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "eventActionBlock", for: indexPath) as? AddNewEventActionTVC {
            
            cell.indicatorLabel.text = ""
            if indexPath.section == 0 {
                if indexPath.row == 0 {
                    cell.actionTitle.text = "新增活動成員"
                    return cell
                }
            } else if indexPath.section == 1 {
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
        if section == 0 {
            return 30
        } else if section == 1 {
            return 30
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 50
        } else if section == 1 {
            return 50
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = headerColor
        if section == 0 {
            var descriptionLabel: UILabel {
                let des = UILabel(frame: CGRect(x: 10, y: 10, width: tableView.bounds.width-10, height: 50))
                des.text = "活動成員"
                des.textColor = UIColor.darkGray
                des.numberOfLines = 0
                des.font = UIFont.boldSystemFont(ofSize: 13)
                des.sizeToFit()
                return des
            }
            headerView.addSubview(descriptionLabel)
            return headerView
        } else if section == 1 {
            var descriptionLabel: UILabel {
                let des = UILabel(frame: CGRect(x: 10, y: 10, width: tableView.bounds.width-10, height: 50))
                des.text = "活動款項"
                des.textColor = UIColor.darkGray
                des.numberOfLines = 0
                des.font = UIFont.boldSystemFont(ofSize: 13)
                des.sizeToFit()
                return des
            }
            headerView.addSubview(descriptionLabel)
            return headerView
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = headerColor
        
        if section == 0 {
            var paymentMemberDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                descriptionLabel.text = "Padi使用者成員們將可以即時看到這筆分款活動的所有款項，以及任何款項變動。"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(paymentMemberDescription)
            return footerView
        } else if section == 1 {
            var paymentMemberDescription: UILabel {
                // because autolayout doesn't work in tableView header, use CGRect to define the frame of label in here.
                let descriptionLabel = UILabel(frame: CGRect(x: 20, y: 10, width: tableView.bounds.width-10, height: 50))
                descriptionLabel.text = "新增一筆新的分款款項到此活動中。"
                descriptionLabel.numberOfLines = 0
                descriptionLabel.font = UIFont.systemFont(ofSize: 13)
                descriptionLabel.textColor = .lightGray
                descriptionLabel.sizeToFit()
                return descriptionLabel
            }
            footerView.addSubview(paymentMemberDescription)
            return footerView
        }
        return footerView
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








