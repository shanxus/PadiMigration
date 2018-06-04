//
//  SingleEventViewVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON
import Instructions

class SingleEventViewVC: UIViewController {

    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    @IBOutlet weak var layoutTableView: UITableView!
    @IBOutlet weak var editBtn: UIButton!
    var isEditingBtnShowing: Bool = true
    
    // delegate classes of singleEvent info.
    var helperDataSource: EventInfoHelperVC! = EventInfoHelperVC()
    var singleEventPayHelper: SingleEventPayHelperVC! = SingleEventPayHelperVC()
    
    @IBOutlet weak var ViewTitle: UILabel!
    var paysCollectonView: UICollectionView!
    
    // this holder is used to store the value of view title so that it can pass the value to view title label when this view is going to be presented.
    // when implement, use a class object to hold the properties for all information that this view needs.
    var viewTitleHolder: String! = ""
    
    var userID: String?
    //var mainEvent: PadiEvent?
    var eventID: String?
    
    /* this variable is used to prevent the edit alert view to keep showing. */
    var isPayEditAlertFinished: Bool = true
    
    var eventMemberCV: UICollectionView?
    var eventMembersID: [String] = []
    
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if isEditingBtnShowing == false {
            editBtn.isUserInteractionEnabled = false
            editBtn.alpha = 0.0
            singleEventPayHelper.shouldShowEditBtn = false
        }
        
        layoutTableView.delegate = self
        layoutTableView.dataSource = self
        layoutTableView.tableFooterView = UIView()
        
        if let userID = userID, let eventID = eventID {
            
            helperDataSource.userID = userID
            helperDataSource.eventID = eventID
            
            /* show pays for single event view */
            let cellAccessIndex = IndexPath(row: 0, section: 4)
            if let targetCell = layoutTableView.cellForRow(at: cellAccessIndex) as? EventPayTVC {
                if let CV = targetCell.EventPayCollectionView {
                    paysCollectonView = CV
                    singleEventPayHelper.thisCollectionView = CV                    
                }
            }
            singleEventPayHelper.userID = userID
            singleEventPayHelper.eventID = eventID
        }
        
        addLongPressRecognizer()
        listenEventChanges()
        listenEventName()
        
        self.coachMarksController.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let finishShowingInstructions = UserDefaults.standard.bool(forKey: "showInstrInSingleEventVC")
        if finishShowingInstructions == false {
            self.coachMarksController.start(on: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.coachMarksController.stop(immediately: true)
    }
    
    @IBAction func editTapped(_ sender: Any) {
        
        let topVC = GeneralService.findTopVC()        
        if let editEventVC = topVC.storyboard?.instantiateViewController(withIdentifier: "AddNewEventVC") as? AddNewEventVC {
            let dispatch = DispatchGroup()
            guard let user = userID, let event = eventID else {return}
            editEventVC.eventNameHolder = viewTitleHolder
            let helper = ExamplePadiEvent()
            helper.fetchEventImageURL(userID: user, eventID: event) { (url: String) in
                editEventVC.eventPhotoURL = url
            }
            editEventVC.viewType = .edit
            editEventVC.userID = userID
            editEventVC.eventID = event
        
            /* fetch friend list () */
            let memberListRef =  ref.child(DBPathStrings.eventDataPath).child(user).child(event).child(DBPathStrings.memberListPath)
            dispatch.enter()
            memberListRef.observeSingleEvent(of: .value) { (snapshot) in
                
                let json = JSON(snapshot.value ?? "")
                var memberList: [String] = []
                for (_, id) in json.dictionaryValue {
                    memberList.append(id.stringValue)
                }
                editEventVC.selectedMember = memberList.sorted()
                dispatch.leave()
            }
            
            dispatch.notify(queue: .main) {
                topVC.present(editEventVC, animated: true, completion: nil)
            }
        }
    }
    
    func listenEventName() {
        guard let user = userID, let event = eventID else {return}
        let helper = ExamplePadiEvent()
        helper.fetchEventName(userID: user, eventID: event) { (name: String) in
            self.ViewTitle.text = name
            self.viewTitleHolder = name
        }
    }
    
    func listenEventChanges() {
        guard let user = userID, let event = eventID else {return}
        let memberListRef = ref.child(DBPathStrings.eventDataPath).child(user).child(event).child(DBPathStrings.memberListPath)
        
        /* listen the member list for the event, and listen for add member. */
        memberListRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            self.eventMembersID.append(json.stringValue)
            if let thisCV = self.eventMemberCV {
                thisCV.reloadData()
            }
        }
        
        let listenChangeRef = ref.child(DBPathStrings.eventDataPath).child(user).child(event)
        listenChangeRef.observe(.childChanged) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            
            /* listen for delete member. */
            if snapshot.key == DBPathStrings.memberListPath {
                var membersAfterChange: [String] = []
                for (_, id) in json.dictionaryValue {
                    membersAfterChange.append(id.stringValue)
                }
                if membersAfterChange.count < self.eventMembersID.count {   // a member is deleted.
                    for each in self.eventMembersID {
                        if membersAfterChange.contains(each) == false {
                            if let removeIndex = self.eventMembersID.index(of: each) {
                                self.eventMembersID.remove(at: removeIndex)
                                self.eventMemberCV?.reloadData()
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    @IBAction func dismissSingleEventView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ViewTitle.text = viewTitleHolder
    }
    
    func addLongPressRecognizer() {
        let rec = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressInPayCollection))
        paysCollectonView.addGestureRecognizer(rec)
    }
    
    @objc func handleLongPressInPayCollection(gestureRecognizer: UIGestureRecognizer) {
        if isPayEditAlertFinished == true {
            isPayEditAlertFinished = !isPayEditAlertFinished
            
            let pressedLocation = gestureRecognizer.location(in: paysCollectonView)
            if let index = paysCollectonView.indexPathForItem(at: pressedLocation) {            
                singleEventPayHelper.handleLongPressInPaysCollectionView(longPressedIndex: index, completion: { (alertFinished) in
                        self.isPayEditAlertFinished = alertFinished
                })
            }
        }
    }
}

extension SingleEventViewVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let dispatch = DispatchGroup()
            let topVC = GeneralService.findTopVC()
            if let showRelationVC = topVC.storyboard?.instantiateViewController(withIdentifier: "showPayRelationVC") as? ShowPayRelationVC {
                guard let event = eventID, let user = userID else {return}
                showRelationVC.userID = userID
                
                var payIDs: [String] = []
                
                /* Fetch pay IDs for a event. */
                let helper = ExamplePadiEvent()
                dispatch.enter()
                helper.fetchAttribute(for: DBPathStrings.paysPath, eventID: event, userID: user) { (fetched:JSON) in
                    for (_, ID) in fetched.dictionaryValue {
                        payIDs.append(ID.stringValue)
                    }
                    dispatch.leave()
                }
                
                dispatch.notify(queue: .main) {
                    showRelationVC.payIDs = payIDs
                    topVC.present(showRelationVC, animated: true, completion: nil)
                }
            }
        }
    }
}

extension SingleEventViewVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 180
        } else if indexPath.section == 1 {
            return 40
        } else if indexPath.section == 2 {
            return 150
        } else if indexPath.section == 3 {
            return 180
        } else {
            return self.view.bounds.height*0.66
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventImageCell", for: indexPath) as? EventPictureTVC {
                if let user = userID, let event = eventID {
                    let helper = ExamplePadiEvent()
                    helper.fetchEventImageURL(userID: user, eventID: event) { (url: String) in
                        let imageURL = URL(string: url)
                        DispatchQueue.main.async {
                            cell.eventImage.kf.setImage(with: imageURL)
                        }
                    }
                }                                
                return cell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "ShowPaymentCell", for: indexPath) as? ShowPaymentTVC {
                cell.title.text = "顯示活動付款資訊"
                cell.indicatorLabel.text = ">"
                return cell
            }
        } else if indexPath.section == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventInfoCell", for: indexPath) as? EventInfoTVC {
                cell.title.text = "活動資訊"
                cell.infoTableView.dataSource = self.helperDataSource
                cell.infoTableView.tableFooterView = UIView()
                return cell
            }
        } else if indexPath.section == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SingleEventMembersTVC", for: indexPath) as? EventMembersTVC {
                cell.title.text = "活動成員"
                // think about how to use this indicator label.
                cell.indicatorLabel.text = ""
                cell.membersCollectionView.dataSource = self
                cell.membersCollectionView.delegate = self
                eventMemberCV = cell.membersCollectionView
                return cell
            }
        } else if indexPath.section == 4 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "EventPayTVC", for: indexPath) as? EventPayTVC {
                cell.title.text = "活動款項"
                cell.EventPayCollectionView.dataSource = self.singleEventPayHelper
                cell.EventPayCollectionView.delegate = self.singleEventPayHelper                
                return cell
            }
        }
        
        return UITableViewCell()
    }
}

// MARK: - dataSource of the singleEvent members collectionView.
extension SingleEventViewVC: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return eventMembersID.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventMembersCVC", for: indexPath) as? EventMembersCVC {
            
            let memberID = eventMembersID[indexPath.row]
            let userRef = ref.child(DBPathStrings.userDataPath).child(memberID)
            userRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                let json = JSON(snapshot.value ?? "")
                let imgURL = json[DBPathStrings.imageURLPath].stringValue
                let name = json[DBPathStrings.namePath].stringValue
                
                DispatchQueue.main.async {
                    cell.MemberName.text = name
                }
                
                let url = URL(string: imgURL)
                cell.MemberImage.kf.setImage(with: url)
                
                // should think about what I want to show here (maybe not the payValue).
                cell.MemberPayValue.text = ""
                
            })
            return cell
        }
        return UICollectionViewCell()
    }
}

//MARK: - delegate of the singleEvent members collectionView.
extension SingleEventViewVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

extension SingleEventViewVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 10.0
        
        return CGSize(width: 80, height: 130)
    }
}

extension SingleEventViewVC: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 2
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        
        if index == 0 {
            return coachMarksController.helper.makeCoachMark(for: editBtn)
        } else {
            let targetIndex = IndexPath(row: 0, section: 1)
            let cell = layoutTableView.cellForRow(at: targetIndex)
            let targetView = cell!.contentView
            return coachMarksController.helper.makeCoachMark(for: targetView)
        }
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        if index == 0 {
            coachViews.bodyView.hintLabel.text = "點擊這邊來編輯此筆分款活動"
            coachViews.bodyView.nextLabel.text = "Ok!"
        } else {
            coachViews.bodyView.hintLabel.text = "點擊這邊來查看此筆活動的分款資訊"
            coachViews.bodyView.nextLabel.text = "Ok!"
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}




