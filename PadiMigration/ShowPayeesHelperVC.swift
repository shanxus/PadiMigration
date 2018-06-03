//
//  ShowPayeesHelperVC.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/25.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class ShowPayeesHelperVC: UIViewController {

    var membersIDList: [String]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension ShowPayeesHelperVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = membersIDList?.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "payeeListCVC", for: indexPath) as? PayeesListCVC {
            guard let list = membersIDList else {return UICollectionViewCell()}
            let helper = ExamplePadiFriends()
            helper.getImageURLString(forSingleFriend: list[indexPath.row], completion: { (url) in
                let imgURL = URL(string: url)
                cell.memberImage.kf.setImage(with: imgURL)
            })
            return cell
        }
        return UICollectionViewCell()
    }
}

extension ShowPayeesHelperVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        print("touch..")
    }
}

extension ShowPayeesHelperVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 10.0
        
        return CGSize(width: 80, height: 100)
    }
}

extension UIImageView {
    func scaledAniamtion() {
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.2, options: .repeat, animations: { 
            self.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }) { (result) in
            UIView.animate(withDuration: 0.6) {
                self.transform = CGAffineTransform.identity
            }
        }
    }
}











