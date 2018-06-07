//
//  MyEventsOverview.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/5.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Kingfisher
import FirebaseDatabase
import FirebaseAuth
import SkeletonView
import Instructions

class MyEventsOverview: UIViewController {

    @IBOutlet weak var layoutTableView: UITableView!
    @IBOutlet weak var viewTitleLabel: UIView!
    
    var eventsCV: UICollectionView!
    var isEventRecordAlertFinished: Bool = true
    
    var helperDataSource: MyEventOverviewHelperVC! = MyEventOverviewHelperVC()
    
    var mainUserEvents: [PadiEvent]! = [] {
        didSet {
            helperDataSource.events = mainUserEvents
            self.updateFavoriteCollectionView()
            self.updateEventsCollectionView()
        }
    }
    var favorites: [PadiEvent] = []
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    var eventDeleteListener: DatabaseReference?
    
    let coachMarksController = CoachMarksController()
    
    override func viewDidLoad() {
        
        if let currentUser = Auth.auth().currentUser {
            
            print("email: ", currentUser.email!)
            print("uid: ", currentUser.uid)
            coachMarksController.dataSource = self
        }
        
        layoutTableView.delegate = self
        layoutTableView.dataSource = self
        
        
        /* use this blank UIView to avoid contents getting hidden */
        let bottomUIView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 49))
        layoutTableView.tableFooterView = bottomUIView
        
        prepareMainUser()
        getCachedDiskSize()
        addLongPressRecognizer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if let _ = Auth.auth().currentUser {
            
            let finishShowingInstructions = UserDefaults.standard.bool(forKey: InstructionControlling.showInstrInOverviewVCFinished)
            if finishShowingInstructions == false {
                coachMarksController.start(on: self)
            }
        } else {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyBoard.instantiateViewController(withIdentifier: "SignUpVC") as? SignUpVC {
                self.present(loginVC, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coachMarksController.stop(immediately: true)
    }
    
    func currentUserImageTapped() {
        let topVC = GeneralService.findTopVC()
        if let userInfoVC = topVC.storyboard?.instantiateViewController(withIdentifier: "CurrentUserInfoVC") as? CurrentUserInfoVC {
            if let currentUser = Auth.auth().currentUser {
                userInfoVC.userID = currentUser.uid
                topVC.present(userInfoVC, animated: true, completion: nil)
            }
        }
    }
    
    func listenEventDelete() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {return}
        eventDeleteListener = ref.child(DBPathStrings.eventDataPath).child(currentUserID)
        eventDeleteListener?.observe(.childRemoved, with: { (snapshot) in
            
            /* remove in this VC. */
            for (index, each) in self.mainUserEvents.enumerated() {
                if each.getID() == snapshot.key {
                    self.mainUserEvents.remove(at: index)
                }
            }
            
            /* remove in helper VC. */
            self.helperDataSource.handleEventDelete(targetEventID: snapshot.key)
        })
    }
    
    func addLongPressRecognizer() {
        let rec = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressInPayRecords))
        let layoutIndex = IndexPath(row: 0, section: 1)
        if let cell = layoutTableView.cellForRow(at: layoutIndex) as? MyEventOverviewEventsTVC {
            eventsCV = cell.eventsCollectionView
            cell.eventsCollectionView.addGestureRecognizer(rec)
        }
    }
    
    @objc func handleLongPressInPayRecords(gestureRecognizer: UIGestureRecognizer) {
        if isEventRecordAlertFinished == true {
            isEventRecordAlertFinished = !isEventRecordAlertFinished
            
            let pressLocation = gestureRecognizer.location(in: eventsCV)
            if let index = eventsCV.indexPathForItem(at: pressLocation) {
                helperDataSource.handleLongPressInEventRecordsCV(longPressedIndex: index) { (alertFinished) in
                    self.isEventRecordAlertFinished = alertFinished
                }
            }
        }
    }
    
    func getCachedDiskSize() {
        ImageCache.default.calculateDiskCacheSize { (size) in
            print("Used disk size by bytes: \(size)")
        }
    }

    func listenEventAdded(userID: String) {
        let listenHelper = ExamplePadiEvent()
        listenHelper.listenAdd(forSpecificUser: userID) { (event) in
            var isContained: Bool = false
            for each in self.mainUserEvents {
                if each.getID() == event.getID() {
                    isContained = true
                }
            }
            if isContained == false {
                self.mainUserEvents.append(event)
            }
        }
    }
    
    func performSegueToSingleEventView() {
        performSegue(withIdentifier: "ShowSingleEvent", sender: self)
    }
    
    func pushViewToSingleEventView() {
        if let singleEventVC = self.storyboard?.instantiateViewController(withIdentifier: "SingleEventVC") as? SingleEventViewVC {
            self.present(singleEventVC, animated: true, completion: nil)
        }
    }
    
    func prepareMainUser() {
        guard let currentUser = Auth.auth().currentUser?.uid else {return}
        self.helperDataSource.userID = currentUser
        self.listenEventAdded(userID: currentUser)
        self.listenEventDelete()
    }
    
    func updateFavoriteCollectionView() {
        let indexForFavorite = IndexPath(row: 0, section: 1)
        if let favoriteTV = self.layoutTableView.cellForRow(at: indexForFavorite) as? MyEventOverviewFavoriteTVC {
            favoriteTV.myFavoriteEventCollectionView.reloadData()
        }
    }
    
    func updateEventsCollectionView() {
        let indexForOverview = IndexPath(row: 0, section: 1)
        if let overviewTV = self.layoutTableView.cellForRow(at: indexForOverview) as? MyEventOverviewEventsTVC {
            overviewTV.eventsCollectionView.reloadData()
        }
    }
}

// MARK: - Delegate of layout TableView.
extension MyEventsOverview: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            currentUserImageTapped()
        }
    }
}

// MARK: - DataSource of layout TableView.
extension MyEventsOverview: UITableViewDataSource {
 
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 120
        }
        /*
        else if indexPath.section == 1 {
            return 200
        }
        */
        else {
            return self.view.bounds.height*0.66
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MyEventOverviewPictureCell", for: indexPath) as? MyEventOverviewPictureTVC {
                
                guard let currentUser = Auth.auth().currentUser else {return cell}
                guard let currentUserID = Auth.auth().currentUser?.uid else {return cell}
                let helper = ExamplePadiMember()
                
                cell.name.isSkeletonable = true
                cell.name.showAnimatedGradientSkeleton()
                helper.fetchName(userID: currentUserID) { (name: String) in
                    DispatchQueue.main.async {
                        cell.name.text = name
                        cell.hideSkeleton()
                    }
                }
                
                cell.picture.isSkeletonable = true
                cell.picture.showAnimatedGradientSkeleton()
                helper.fetchUserImageURL(userID: currentUserID) { (url: String) in
                    DispatchQueue.main.async {
                        let imgURL = URL(string: url)
                        cell.picture.kf.setImage(with: imgURL)
                        cell.hideSkeleton()
                    }
                }
                
                if let account = currentUser.email {
                    cell.account.text = account
                }
                
                return cell
            }
        }
        /*
        else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MyEventOverviewFavoriteCell", for: indexPath) as? MyEventOverviewFavoriteTVC {
                cell.title.text = "❤︎我的最愛活動"
                cell.viewAllLabel.text = ""
                cell.myFavoriteEventCollectionView.dataSource = self
                cell.myFavoriteEventCollectionView.delegate = self
                return cell
            }
        }
        */
        else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "MyEventOverviewEventsCell", for: indexPath) as? MyEventOverviewEventsTVC {
                cell.title.text = "我的活動"
                cell.eventsCollectionView.dataSource = self.helperDataSource
                cell.eventsCollectionView.delegate = self.helperDataSource
                self.helperDataSource.thisCV = cell.eventsCollectionView
                return cell
            }
        }
        
        return UITableViewCell()
    }
}

// MARK: - DataSource of Favorite CollectionView of MyEventOverview.

extension MyEventsOverview: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let mainUserEvents = mainUserEvents {
            favorites = mainUserEvents.filter({ (event) -> Bool in
                return event.getIsFavorite() == true
            })
            return favorites.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let mainUserEvents = mainUserEvents {
            favorites = mainUserEvents.filter({ (event) -> Bool in
                return event.getIsFavorite() == true
            })
            
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myEventOverviewFavoriteCVC", for: indexPath) as? MyEventOverviewFavoriteCVC {
                let helper = ExamplePadiEvent()
                let imgURL = favorites[indexPath.row].getImageURLString()
                let url = URL(string: imgURL)
                cell.image.kf.indicatorType = .activity
                cell.image.kf.setImage(with: url)
                
                guard let userID = Auth.auth().currentUser?.uid else {return UICollectionViewCell()}
                let eventID = favorites[indexPath.row].getID()
                helper.fetchEventName(userID: userID, eventID: eventID) { (name: String) in
                    DispatchQueue.main.async {
                        cell.Name.text = name
                    }
                }
                
                helper.fetchTotalValue(userID: userID, eventID: eventID) { (value: Float) in
                    DispatchQueue.main.async {
                        cell.value.text = "＄ \(value)"
                    }
                }                
                
                let timeString = favorites[indexPath.row].getEventDateString()
                cell.date.text = timeString
                
                return cell
            } else {
                return UICollectionViewCell()
            }
        } else {
            return UICollectionViewCell()
        }
    }
}

// MARK: - Delegate of Favorite CollectionView of MyEventOverview.

extension MyEventsOverview: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let topVC = GeneralService.findTopVC()
        if let singleEventViewVC = topVC.storyboard?.instantiateViewController(withIdentifier: "SingleEventVC") as? SingleEventViewVC {
            guard let currentUserID = Auth.auth().currentUser?.uid else {return}
            let event = favorites[indexPath.row]
            singleEventViewVC.viewTitleHolder = event.getName()            
            singleEventViewVC.eventID = event.getID()
            singleEventViewVC.userID = currentUserID
            topVC.present(singleEventViewVC, animated:true, completion: {
                collectionView.deselectItem(at: indexPath, animated: true)
            })
        }
    }
}

extension MyEventsOverview: UICollectionViewDelegateFlowLayout {
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
     
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 10.0
        
        return CGSize(width: 80, height: 130)
    }
}

// MARK: - implementation of dataSource and delegate for Instructions.

extension MyEventsOverview: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 2
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        
        if index == 0 {
            let targetIndex = IndexPath(row: 0, section: 0)
            let targetCell = layoutTableView.cellForRow(at: targetIndex) as! MyEventOverviewPictureTVC
            return coachMarksController.helper.makeCoachMark(for: targetCell.contentView)
        } else {
            return coachMarksController.helper.makeCoachMark(for: self.viewTitleLabel)
        }
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        if index == 0 {
            coachViews.bodyView.hintLabel.text = "在這邊設定您的頭像以及使用者暱稱"
            coachViews.bodyView.nextLabel.text = InstructionsShowing.showNext
        } else if index == 1 {
            coachViews.bodyView.hintLabel.text = "所有您所創立的分款活動都會顯示在這個頁面"
            coachViews.bodyView.nextLabel.text = InstructionsShowing.showNext
            UserDefaults.standard.set(true, forKey: InstructionControlling.showInstrInOverviewVCFinished)
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }
}















