//
//  MyFriendOverviewVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/16.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseAuth
import SkeletonView

enum FriendsVCType: String {
    case friendOverview = "friendOverview"
    case eventFriendList = "eventFriendList"
}

/* prepare for displaying different txt. */
class friendOverviewInfo {
    var titleTxt: String?
    var actionTxt: String?
    init(titleTxt: String = "", actionTxt: String = "") {
        self.titleTxt = titleTxt
        self.actionTxt = actionTxt
    }
}

class MyFriendOverviewVC: UIViewController {

    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var friendListingTable: UITableView!
    @IBOutlet weak var actionButton: UIButton!
    
    let headerColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1)
    
    var friends: [String]? {
        didSet{
            friends = friends?.sorted()
            
            /* add self ID into the first place. */
            if let vcType = friendVCType, vcType == .eventFriendList {
                guard let currentUserID = Auth.auth().currentUser?.uid else {return}
                friends?.insert(currentUserID, at: 0)
            }
            
            friendListingTable.reloadData()
            self.friendListingTable.isUserInteractionEnabled = true
        }
    }    
    
    var userID: String?
    var isEditingAlertShowing: Bool = false
    
    var selected: [String] = []
    var selectedMembersDelegate: PassSelectedMemberback?
    
    var friendVCType: FriendsVCType?
    var prepareDisplaying: friendOverviewInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleViewTitleTxt()
        handleActionTxt()
        
        //friendListingTable.isSkeletonable = true
        friendListingTable.dataSource = self
        friendListingTable.delegate = self
        
        
        friendListingTable.isUserInteractionEnabled = false
        friendListingTable.tableFooterView = UIView()
        friendListingTable.backgroundColor = headerColor
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressOnFriendCell))
        friendListingTable.addGestureRecognizer(longPress)
        
        let helper = ExampleMainUser.shareInstance
        if let currentUserID = Auth.auth().currentUser?.uid {
            helper.fetchFriendsList(userID: currentUserID) { (list: [String]) in
                self.friends = list
            }
        }
    }
    
    @objc func longPressOnFriendCell(recognizer: UIGestureRecognizer) {
        let location = recognizer.location(in: friendListingTable)
        if let pressedIndex = friendListingTable.indexPathForRow(at: location) {
            if let pressedCell = friendListingTable.cellForRow(at: pressedIndex) as? MyFriendOverviewTVC {
                if pressedCell.friendType.text == "Padi使用者" {
                    
                } else if pressedCell.friendType.text == "自定義好友" {
                    if let friendID = friends?[pressedIndex.row] {
                        showEditFriendAlert(friendID: friendID)
                    }
                }
            }
        }
    }
    
    func showEditFriendAlert(friendID: String) {
        if isEditingAlertShowing == false {
            let topVC = GeneralService.findTopVC()
            isEditingAlertShowing = true
            let alert = UIAlertController(title: "自定義好友", message: "請選擇您想要做什麼", preferredStyle: .actionSheet)
            let edit = UIAlertAction(title: "編輯", style: .default) { (action) in
                self.isEditingAlertShowing = false
                
                if let currentUserinfoVC = topVC.storyboard?.instantiateViewController(withIdentifier: "CurrentUserInfoVC") as? CurrentUserInfoVC {
                    currentUserinfoVC.userID = friendID
                    topVC.present(currentUserinfoVC, animated: true, completion: nil)
                }
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                self.isEditingAlertShowing = false
            }
            
            alert.addAction(edit)
            alert.addAction(cancel)
            topVC.present(alert, animated: true, completion: nil)
        }
    }
    
    func handleViewTitleTxt() {
        if friendVCType == FriendsVCType.eventFriendList {
            if let titleTxt = prepareDisplaying?.titleTxt {
                viewTitleLabel.text = titleTxt
            }
        }
    }
    
    func handleActionTxt() {
        if friendVCType == FriendsVCType.eventFriendList {
            if let actionTxt = prepareDisplaying?.actionTxt {
                actionButton.setTitle(actionTxt, for: .normal)
            }
        }
    }

    @IBAction func addNewFriendAction(_ sender: Any) {
        selectedMembersDelegate?.passSelectedMember(member: selected)
        self.dismiss(animated: true, completion: nil)
    }
}

extension MyFriendOverviewVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        /* show friend list for adding new event. */
        if friendVCType == FriendsVCType.eventFriendList {
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            guard let id = friends?[indexPath.row] else { return }
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                guard let removeIndex = selected.index(of: id) else { return }
                selected.remove(at: removeIndex)
            } else if cell.accessoryType == .none {
                cell.accessoryType = .checkmark
                selected.append(id)
            }
        } else { /* show friend list for friends overview. */
            
        
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

/*
extension MyFriendOverviewVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = friends?.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "myFriendOverviewTVC", for: indexPath) as? MyFriendOverviewTVC {
            
            guard let currentUserID = Auth.auth().currentUser?.uid else {return MyFriendOverviewTVC()}
            
            let helper = ExamplePadiMember()
            if let friends = friends {
                let userID = friends[indexPath.row]
                helper.fetchUserImageURL(userID: userID) { (url: String) in
                    let urlString = URL(string: url)
                    cell.friendImage.kf.setImage(with: urlString)
                }
                
                helper.fetchName(userID: userID) { (name: String) in
                    DispatchQueue.main.async {
                        cell.friendName.text = name
                    }
                }
                
                helper.fetchFriendType(currentUserID: currentUserID, friendID: userID) { (type: String) in
                    DispatchQueue.main.async {
                        cell.friendType.text = type
                    }
                }
                
                let VCtype = friendVCType
                if VCtype == FriendsVCType.eventFriendList {
                    let exist = selected.contains(friends[indexPath.row])
                    cell.accessoryType = (exist == true) ? .checkmark : .none
                }
            }
            return cell
        }
        return UITableViewCell()
    }
}
*/

extension MyFriendOverviewVC: SkeletonTableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = friends?.count {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "myFriendOverviewTVC", for: indexPath) as? MyFriendOverviewTVC {
            
            guard let currentUserID = Auth.auth().currentUser?.uid else {return MyFriendOverviewTVC()}
            
            let helper = ExamplePadiMember()
            if let friends = friends {
                let userID = friends[indexPath.row]
                
                cell.friendImage.isSkeletonable = true
                cell.friendImage.showAnimatedGradientSkeleton()
                helper.fetchUserImageURL(userID: userID) { (url: String) in
                    let urlString = URL(string: url)
                    cell.friendImage.kf.setImage(with: urlString)
                    cell.friendImage.hideSkeleton()
                }
                
                cell.friendName.isSkeletonable = true
                cell.friendName.showAnimatedGradientSkeleton()
                helper.fetchName(userID: userID) { (name: String) in
                    DispatchQueue.main.async {
                        cell.friendName.text = name
                        cell.friendName.hideSkeleton()
                    }
                }
                
                cell.friendType.isSkeletonable = true
                cell.friendType.showAnimatedGradientSkeleton()
                helper.fetchFriendType(currentUserID: currentUserID, friendID: userID) { (type: String) in
                    DispatchQueue.main.async {
                        cell.friendType.text = type
                        cell.friendType.hideSkeleton()
                    }
                }
                
                let VCtype = friendVCType
                if VCtype == FriendsVCType.eventFriendList {
                    let exist = selected.contains(friends[indexPath.row])
                    cell.accessoryType = (exist == true) ? .checkmark : .none
                }
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdenfierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "myFriendOverviewTVC"
    }
    
}









