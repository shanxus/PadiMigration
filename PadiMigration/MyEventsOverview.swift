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

class MyEventsOverview: UIViewController {

    @IBOutlet weak var layoutTableView: UITableView!
    @IBOutlet weak var viewTitleLabel: UIView!
    
    @IBOutlet weak var currentUserImage: UIImageView!
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
    
    override func viewDidLoad() {
        
        if let currentUser = Auth.auth().currentUser {
            
            print("email: ", currentUser.email!)
            print("uid: ", currentUser.uid)
            loadCurrentUserImage()
        }
        
        currentUserImage.isUserInteractionEnabled = true
        let tapCurrentUserImage = UITapGestureRecognizer(target: self, action: #selector(currentUserImageTapped))
        currentUserImage.addGestureRecognizer(tapCurrentUserImage)
        
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
        //super.viewDidAppear(true)
        if let _ = Auth.auth().currentUser {                        
        } else {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyBoard.instantiateViewController(withIdentifier: "SignUpVC") as? SignUpVC {
                self.present(loginVC, animated: true, completion: nil)
            }
        }
    }
    
    @objc func currentUserImageTapped(recognizer: UIGestureRecognizer) {
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
        let layoutIndex = IndexPath(row: 0, section: 2)
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
            print("listenEventAdded got called...")
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
    
    func loadCurrentUserImage() {
        if let currentUserID = Auth.auth().currentUser?.uid {
            let helper = ExamplePadiMember()
            helper.fetchUserImageURL(userID: currentUserID) { (imageURL: String) in
                DispatchQueue.main.async {
                    let url = URL(string: imageURL)
                    self.currentUserImage.kf.setImage(with: url)
                }
            }
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
        let indexForOverview = IndexPath(row: 0, section: 2)
        if let overviewTV = self.layoutTableView.cellForRow(at: indexForOverview) as? MyEventOverviewEventsTVC {
            overviewTV.eventsCollectionView.reloadData()
        }
    }
}

// MARK: - Delegate of layout TableView.
extension MyEventsOverview: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - DataSource of layout TableView.
extension MyEventsOverview: UITableViewDataSource {
 
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 180
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
                cell.picture.image = #imageLiteral(resourceName: "CCC")
                cell.value.text = "$ 300"
                cell.title.text = "中興新村"
                cell.date.text = "2017/10/31"
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

















