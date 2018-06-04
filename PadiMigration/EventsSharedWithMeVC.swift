//
//  EventsSharedWithMeVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/5/31.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Instructions

class EventsSharedWithMeVC: UIViewController {

    @IBOutlet weak var navigationLabel: CustomView!
    @IBOutlet weak var viewTitleLabel: UILabel!
    @IBOutlet weak var sharedEventsTable: UITableView!
    
    var sharedEvents: [String]? {
        didSet {
            sharedEventsTable.reloadData()
        }
    }
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sharedEventsTable.delegate = self
        sharedEventsTable.dataSource = self
        sharedEventsTable.tableFooterView = UIView()
        
        listenToSharedEvents()
        
        self.coachMarksController.dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let finishShowingInstructions = UserDefaults.standard.bool(forKey: "showInstrInEventsSharedWithMeVC")
        if finishShowingInstructions == false {
            self.coachMarksController.start(on: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.coachMarksController.stop(immediately: true)
    }
    
    func listenToSharedEvents() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        let helper = ExamplePadiEvent()
        helper.fetchSharedEvents(userID: currentUserID) { (list: [String]) in
            self.sharedEvents = list
        }
    }
}

extension EventsSharedWithMeVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let event = sharedEvents?[indexPath.row] else {return}
        
        let topVC = GeneralService.findTopVC()
        if let singleEventVC = topVC.storyboard?.instantiateViewController(withIdentifier: "SingleEventVC") as? SingleEventViewVC {
            let dispatch = DispatchGroup()
            let helper = ExamplePadiEvent()
            
            singleEventVC.eventID = event            
            singleEventVC.isEditingBtnShowing = false
            
            dispatch.enter()
            helper.fetchEventNameWithoutCreatorID(eventID: event) { (eventName: String) in
                singleEventVC.viewTitleHolder = eventName
                dispatch.leave()
            }
            dispatch.enter()
            helper.getEventCreatrorID(eventID: event) { (creatorID: String) in
                singleEventVC.userID = creatorID
                dispatch.leave()
            }
            
            dispatch.notify(queue: .main) {
                topVC.present(singleEventVC, animated: true, completion: nil)
            }
        }
    }
}

extension EventsSharedWithMeVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sharedEvents = sharedEvents else {
            let reminderTxt = UILabel()
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
            reminderTxt.frame = frame
            reminderTxt.textAlignment = .center
            reminderTxt.text = "還沒有與您分享的活動哦！\n快加入好友並請好友分享活動給您吧！"
            reminderTxt.numberOfLines = 0
            reminderTxt.sizeToFit()
            tableView.backgroundView = reminderTxt
            return 0
        }
        tableView.backgroundView = UIView()
        return sharedEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "sharedEventsCell", for: indexPath) as? SharedEventsTVC else { return UITableViewCell() }
        
        guard let currentUserID = Auth.auth().currentUser?.uid else {return cell}
        guard let eventID = sharedEvents?[indexPath.row] else {return cell}
        let helper = ExamplePadiEvent()
        
        // fetch eventImage.
        helper.fetchSharedEventImageURL(eventID: eventID) { (url) in
            let imgURL = URL(string: url)
            DispatchQueue.main.async {
                cell.eventImage.kf.setImage(with: imgURL)
            }
        }
        
        // fetch event name.
        helper.fetchSharedEventName(eventID: eventID) { (name: String) in
            DispatchQueue.main.async {
                cell.eventName.text = name
            }
        }
        
        return cell
    }
    
}

extension EventsSharedWithMeVC: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController,
                              coachMarkAt index: Int) -> CoachMark {
        return coachMarksController.helper.makeCoachMark(for: navigationLabel)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        coachViews.bodyView.hintLabel.text = "當您朋友將您加入一筆分款活動中時，您可以立即在這邊看到"
        coachViews.bodyView.nextLabel.text = "Ok!"
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}


















