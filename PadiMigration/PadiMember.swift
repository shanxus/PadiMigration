//
//  PadiMember.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/17.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftyJSON

class PadiMember {
    private var ID: String!
    
    init(withID ID: String) {
        self.ID = ID
    }
    
    // MARK: - getter methods.
    func getID() -> String {
        return self.ID
    }
}

class ExamplePadiMember {
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    func storeSelfDefinedMember(memberID: String, imgURL: String, memberName: String) {
        let targetRef = ref.child(DBPathStrings.userDataPath).child(memberID)
        targetRef.setValue(["\(DBPathStrings.imageURLPath)":imgURL,
                            "\(DBPathStrings.namePath)":memberName])
    }
    
    func store(imageURL: String, userID: String) {
        let imgSaveRef = ref.child(DBPathStrings.userDataPath).child(userID).child(DBPathStrings.imageURLPath)
        imgSaveRef.setValue(imageURL)
    }
    
    func store(userName: String, userID: String) {
        let nameSaveRef = ref.child(DBPathStrings.userDataPath).child(userID).child(DBPathStrings.namePath)
        nameSaveRef.setValue(userName)
    }
    
    func fetchName(userID: String, completion: @escaping ((_ name: String) -> Void)) {
        let nameRef = ref.child(DBPathStrings.userDataPath).child(userID).child(DBPathStrings.namePath)
        nameRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let fetchedName = json.string {
                completion(fetchedName)
            }
        }
        
        let userRef = ref.child(DBPathStrings.userDataPath).child(userID)
        userRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.namePath {
                let json = JSON(snapshot.value ?? "")
                if let newName = json.string {
                    completion(newName)
                }
            }
        }
    }
    
    func fetchFriendType(currentUserID: String, friendID: String, completion: @escaping ((_ type: String) -> Void)) {
        if currentUserID == friendID {
            completion("目前使用者")
        }
        let friendRef = ref.child(DBPathStrings.friendDataPath).child(currentUserID).child(friendID).child(DBPathStrings.friendTypePath)
        friendRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let friendType = json.string {
                if friendType == DBPathStrings.padiUser {
                    completion("Padi使用者")
                } else if friendType == DBPathStrings.selfDefined {
                    completion("自定義好友")
                }
            }
        }
    }
    
    func fetchUserImageURL(userID: String, completion: @escaping ((_ imageURL: String) -> Void)) {
        let imageURLRef = ref.child(DBPathStrings.userDataPath).child(userID).child(DBPathStrings.imageURLPath)
        imageURLRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let url = json.string {
                completion(url)
            }
        }
        
        let userRef = ref.child(DBPathStrings.userDataPath).child(userID)
        userRef.observe(.childAdded) { (snapshot) in
            if snapshot.key == DBPathStrings.imageURLPath {
                let json = JSON(snapshot.value ?? "")
                if let url = json.string {
                    completion(url)
                }
            }
        }
        
        userRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.imageURLPath {
                let json = JSON(snapshot.value ?? "")
                if let url = json.string {
                    completion(url)
                }
            }
        }
    }
}















