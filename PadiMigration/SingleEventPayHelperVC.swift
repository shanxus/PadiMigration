//
//  SingleEventPayHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/12.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

class SingleEventPayHelperVC: UIViewController {

    var thisCollectionView: UICollectionView!
    var eventID: String? {
        didSet {
            guard let userID = userID else {return}
            guard let eventID = eventID else {return}
            let listenPaysHelper = ExamplePadiEvent()
            listenPaysHelper.listenPaysAdded(forEvent: eventID, forUser: userID) { (pay) in
                
                if let _ = self.paysID {                    
                    self.paysID?.append(pay)
                } else {
                    var arr: [String] = []
                    arr.append(pay)
                    self.paysID = arr
                }
            }
            
            listenPaysHelper.listenPaysRemoved(forEvent: eventID, forUser: userID) { (pay) in
                if let removeIndex = self.paysID?.index(of: pay) {
                    self.paysID?.remove(at: removeIndex)
                }
            }
        }
    }
    var userID: String?
    var paysID: [String]? {
        
        didSet {
            thisCollectionView.reloadData()
        }
    }
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    /* use this dictionary to store the name of pays for fast accessing */
    var paysNameDic: [String:String] = [:]
    
    var shouldShowEditBtn: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func handleLongPressInPaysCollectionView(longPressedIndex index: IndexPath, completion: @escaping ((_ finished: Bool) -> Void)) {
        guard let payID = paysID?[index.row] else {return}
        guard let targetPayName = paysNameDic[payID] else {return}
        let alert = UIAlertController(title: "編輯款項", message: targetPayName, preferredStyle: .actionSheet)
        
        let delete = UIAlertAction(title: "刪除款項", style: .destructive) { (action) in
            let helper = ExamplePay()
            if let user = self.userID, let event = self.eventID, let pay = self.paysID?[index.row] {
                helper.removeFromDB(userID: user, eventID: event, payID: pay)
            }
            completion(true)
        }
        
        /* implement this later.
        let edit = UIAlertAction(title: "修改款項名稱", style: .default) { (action) in
            
            completion(true)
        }
         */
        
        let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
            completion(true)
        }
        
        alert.addAction(delete)
        //alert.addAction(edit)
        alert.addAction(cancel)
        
        let topVC = GeneralService.findTopVC()
        topVC.present(alert, animated: true, completion: nil)
    }
}

// MARK: - dataSource of the singleEventView's pay.
extension SingleEventPayHelperVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let count = paysID?.count else {return 0}
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventPayCVC", for: indexPath) as? EventPayCVC {            
            if let path = paysID?[indexPath.row], let userID = userID {
                let helper = ExamplePay()
                helper.fetchPayName(payID: path, userID: userID, completion: { (name: String) in
                    self.paysNameDic[path] = name
                    cell.payTitle.text = name
                })
                helper.fetchServiceChargeValue(payID: path, userID: userID, completion: { (value: Float) in
                    cell.descriptionLabel.text = "服務費: \(value) %"
                })
                helper.fetchPayAttribute(for: DBPathStrings.timePath, payID: path, userID: userID, completion: { (fetched: JSON) in
                    if let time = fetched.double {
                        let timeString = EntityHelperClass.getPadiEntityDateString(with: time)
                        cell.payDate.text = timeString
                    }
                })
                helper.fetchPayImage(payID: path, userID: userID, completion: { (url: String) in
                    let imageUrl = URL(string: url)
                    cell.payImage.kf.setImage(with: imageUrl)
                })
                if let userID = self.userID {
                    helper.fetchPayValue(userID: userID, payID: path, completion: { (value: Float) in
                        DispatchQueue.main.async {
                            cell.payValue.text = "$ \(value)"
                        }
                    })
                }
            }
            cell.accessIndicator.text = ">"
            return cell
        }
        
        return UICollectionViewCell()
    }
}

// MARK: - delegate of the singleEventView's pay.
extension SingleEventPayHelperVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topVC = GeneralService.findTopVC()
        if let singlePayVC = topVC.storyboard?.instantiateViewController(withIdentifier: "singlePayVC") as? SinglePayVC {
            if let id = paysID?[indexPath.row], let userID = userID, let eventID = eventID {
                singlePayVC.payID = id
                singlePayVC.userID = userID
                singlePayVC.eventID = eventID
                if shouldShowEditBtn == false {
                    singlePayVC.isEditingBtnShowing = false
                }
                let helper = ExamplePay()
                helper.fetchPayAttribute(for: DBPathStrings.namePath, payID: id, userID: userID, completion: { (fetchedValue) in
                    singlePayVC.viewTitle.text = fetchedValue.stringValue
                })
            }
            topVC.present(singlePayVC, animated:true, completion:nil)
        }
    }
}

extension SingleEventPayHelperVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 2.0
        
        return CGSize(width: collectionView.bounds.width, height: 60)
    }
}









