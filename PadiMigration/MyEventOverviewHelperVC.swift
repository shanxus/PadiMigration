//
//  MyEventOverviewHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/6.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import SkeletonView

class MyEventOverviewHelperVC: UIViewController {

    var thisCV: UICollectionView!
    var userID: String?
    var events: [PadiEvent]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func handleEventDelete(targetEventID: String) {
        if let count = events?.count {
            for index in 0..<count {
                if events?[index].getID() == targetEventID {
                    events?.remove(at: index)
                    let indexToDelete = IndexPath(item: index, section: 0)
                    thisCV.deleteItems(at: [indexToDelete])
                    break
                }
            }
        }
    }
    
    func handleLongPressInEventRecordsCV(longPressedIndex: IndexPath, completion: @escaping ((_ finished: Bool) -> Void)) {
        guard let user = userID, let event = events?[longPressedIndex.item].getID() else {return}
        let helper = ExamplePadiEvent()
        
        if let msg = events?[longPressedIndex.item].getName() {
            let alert = UIAlertController(title: "編輯活動", message: msg, preferredStyle: .actionSheet)
            let delete = UIAlertAction(title: "刪除", style: .destructive) { (action) in
                helper.delete(userID: user, eventID: event)
                completion(true)
            }
            let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                completion(true)
            }
            
            alert.addAction(delete)
            alert.addAction(cancel)
            
            let topVC = GeneralService.findTopVC()
            topVC.present(alert, animated: true, completion: nil)
        }
    }
}

extension MyEventOverviewHelperVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let topVC = GeneralService.findTopVC()
        if let singleEventViewVC = topVC.storyboard?.instantiateViewController(withIdentifier: "SingleEventVC") as? SingleEventViewVC {
            if let event = self.events?[indexPath.row], let userID = userID {
                singleEventViewVC.viewTitleHolder = event.getName()                
                singleEventViewVC.eventID = event.getID()
                singleEventViewVC.userID = userID
            }
            topVC.present(singleEventViewVC, animated:true, completion:nil)
        }
    }
}

extension MyEventOverviewHelperVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 2.0
        
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
}

extension MyEventOverviewHelperVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let events = events else {
            let reminderTxt = UILabel()
            reminderTxt.font = UIFont.systemFont(ofSize: 13)
            reminderTxt.alpha = 0.8
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
            reminderTxt.frame = frame
            reminderTxt.textAlignment = .center
            reminderTxt.text = "您還沒有建立任何一筆分款活動！\n快跟好友一起分款吧！"
            reminderTxt.numberOfLines = 0
            reminderTxt.sizeToFit()
            collectionView.backgroundView = reminderTxt
            return 0
        }
        collectionView.backgroundView = UIView()
        return events.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if events == nil {
            // should show something when data is preparing/empty.
            return UICollectionViewCell()
        }
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myEventOverviewEventsCVC", for: indexPath) as? MyEventOverviewEventsCVC {
            
            guard let event = self.events?[indexPath.row] else {return UICollectionViewCell()}
            let helper = ExamplePadiEvent()
            
            if let userID = userID {
                helper.fetchEventImageURL(userID: userID, eventID: event.getID()) { (url: String) in
                    let url = URL(string: url)
                    cell.image.kf.setImage(with: url)
                }
            }            
            
            if let userID = userID {
                helper.fetchEventName(userID: userID, eventID: event.getID()) { (name: String) in
                    DispatchQueue.main.async {
                        cell.name.text = name
                    }
                }
            }
            
            let timeString = event.getEventDateString()
            cell.date.text = timeString
                        
            cell.accessIndicator.text = ">"
            
            if let userID = userID {
                helper.fetchTotalValue(userID: userID, eventID: event.getID()) { (value: Float) in
                    DispatchQueue.main.async {
                        cell.eventValue.text = "$ \(value)"
                    }
                }
            }
            
            if let userID = userID {
                helper.fetchPayCount(userID: userID, eventID: event.getID()) { (count: Int) in
                    DispatchQueue.main.async {
                        cell.eventRecordNumber.text = "(\(count) 筆)"
                    }
                }
            }
            return cell
        }
        
        
        return UICollectionViewCell()
    }
}











