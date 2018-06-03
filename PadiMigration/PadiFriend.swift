//
//  PadiFriend.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/17.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

enum PadiFriendType: String{
    case PadiUser
    case selfDefinedUser
}

class PadiFriend {
    private var id: String!
    private var friendType: PadiFriendType!
    
    init(withID ID: String, type: PadiFriendType) {
        self.id = ID
        self.friendType = type
    }
    
    // MARK: - getter methods.
    func getID() -> String {
        return self.id
    }
    
    func getType() -> PadiFriendType {
        return self.friendType
    }
    
}

class ExamplePadiFriends {
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    init() {}
    
    func getFriends(forSpecificUser id: String, completion: @escaping ((_ friends: [PadiFriend]) -> Void )) {
        
        var friends: [PadiFriend] = []
        
        let friendRef = ref.child(DBPathStrings.friendDataPath).child(id)
        friendRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (key, value):(String, JSON) in json {
                let id = key
                let type = value[DBPathStrings.friendTypePath].stringValue == "selfDefined" ? PadiFriendType.selfDefinedUser : PadiFriendType.PadiUser
                
                let newExampleFriend = PadiFriend(withID: id, type: type)
                friends.append(newExampleFriend)
            }
            completion(friends)
        })
    }
    
    func getFriendsID(forUser id: String, completion: @escaping (_ list: [String]) -> Void) {
        let friendsRef = ref.child(DBPathStrings.friendDataPath).child(id)
        friendsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            var friendsIDList: [String] = []
            
            let json = JSON(snapshot.value ?? "")
            for (friendID, _) in json {                
                friendsIDList.append(friendID)
            }
            completion(friendsIDList)
        })
    }
    
    func getSingleFriend(withFriendID id: String, userID: String, completion: @escaping ((_ friend: PadiFriend) -> Void)) {
        
        let friendRef = ref.child(DBPathStrings.friendDataPath).child(userID).child(id)
        friendRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (_, value):(String, JSON) in json {
                let type = value[DBPathStrings.friendTypePath].stringValue == "selfDefined" ? PadiFriendType.selfDefinedUser : PadiFriendType.PadiUser
                
                let newExampleFriend = PadiFriend(withID: id, type: type)
                completion(newExampleFriend)
            }
        })
    }
    
    func getImage(forSingleFriend id: String, completion: @escaping ((_ image: UIImage) -> Void)) {
        let friendRef = ref.child(DBPathStrings.userDataPath).child(id)
        friendRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let imgURL = json[DBPathStrings.imageURLPath].stringValue
            
            let url = URL(string: imgURL)
            let request = URLRequest(url: url!)
            let session = URLSession.shared
            
            session.dataTask(with: request, completionHandler: { (data, response, error) in
                if let data = data {
                    if let img = UIImage(data: data) {
                        completion(img)
                    }
                }
            }).resume()
        })
    }
    
    func getImageURLString(forSingleFriend id: String, completion: @escaping ((_ imageURL: String) -> Void)) {
        let friendRef = ref.child(DBPathStrings.userDataPath).child(id)
        friendRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let imgURL = json[DBPathStrings.imageURLPath].stringValue
            completion(imgURL)
        })
    }
    
    func getName(forSingleFriend id: String, completion: @escaping ((_ name: String) -> Void)) {
        let friendRef = ref.child(DBPathStrings.userDataPath).child(id)
        friendRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let name = json[DBPathStrings.namePath].stringValue
            
            completion(name)
        })
    }
    
    func store(friendID: String, type: PadiFriendType, userID: String) {
        let finalRef = ref.child(DBPathStrings.friendDataPath).child(userID).child(friendID).child(DBPathStrings.friendTypePath)
        let value = type == PadiFriendType.selfDefinedUser ? "selfDefined" : "PadiUser"
        finalRef.setValue(value)
    }
    
    func storeIntoDB(friend: PadiFriend, userID: String) {
        let id = friend.getID()
        let type = friend.getType()
        store(friendID: id, type: type, userID: userID)
    }
}












