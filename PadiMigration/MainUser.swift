//
//  MainUser.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/27.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SwiftyJSON

final class MainUser {
    
    // MARK: - properties.
    private var account: String!
    private var name: String!
    private var imageURL: String!
    private var id: String! // this should be the Firebase user token.
    private var friends: [String]! = []
    private var events: [String]! = []
    
    init(with name: String, ID: String, account: String, imageURL: String, friends: [String], events: [String]) {
        self.id = ID
        self.account = account
        self.name = name
        self.imageURL = imageURL
        self.id = ID
        self.events = events
        self.friends = friends
    }
    
    // MARK: - getter methods.
    func getAccount() -> String {
        return self.account
    }
    
    func getName() -> String {
        return self.name
    }
    
    func getImageURLString() -> String {
        return self.imageURL
    }
    
    func getID() -> String {
        return self.id
    }
    
    func getFriendCollectionID() -> [String] {
        return self.friends
    }
    
    func getEventsID() -> [String] {
        return self.events
    }
    
    // MARK: - setter methods.
    func setName(withNew name: String) {
        self.name = name
    }
    
    func setImageURLString(withNew string: String) {
        self.imageURL = string
    }
    
    func setFriendsCollectionID(with newfriends: [String]) {
        self.friends = newfriends
    }
    
    func addNewFriend(withID id: String) {
        self.friends.append(id)
    }
    
    func setEventsCollectionID(with newEvents: [String]) {
        self.events = newEvents
    }
    
    func addNewEvent(withID id: String) {
        self.events.append(id)
    }
}

class ExampleMainUser {
    
    var _mainUser: MainUser?
    
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    static let shareInstance = ExampleMainUser()
    
    private init() {}
    
    func getMainUser(withUserID ID: String, completion: @escaping ((_ mainUser: MainUser) -> Void)) {
        
        let dispatch = DispatchGroup()
        
        if let mainUser = _mainUser {
            completion(mainUser)
        } else {
            var friendsList: [String] = []
            var eventsList: [String] = []
            
            let mainUserRef = ref.child(DBPathStrings.userDataPath).child(ID)
            mainUserRef.observeSingleEvent(of: .value, with: { (snapshot) in
                let json = JSON(snapshot.value ?? "")
                                
                let account = json[DBPathStrings.accountPath].stringValue
                let events = json[DBPathStrings.eventsPath]
                for (_, eventID) in events {
                    let id = eventID.stringValue
                    eventsList.append(id)
                }
                let friendHelper = ExamplePadiFriends()
                
                dispatch.enter()
                friendHelper.getFriendsID(forUser: ID, completion: { (list) in
                    friendsList = list
                    dispatch.leave()
                })
                                
                let url = json[DBPathStrings.imageURLPath].stringValue
                let name = json[DBPathStrings.namePath].stringValue
                
                dispatch.notify(queue: .main, execute: {                    
                    let newMainUser = MainUser(with: name, ID: ID, account: account, imageURL: url, friends: friendsList, events: eventsList)
                    self._mainUser = newMainUser
                    completion(newMainUser)
                })                
            })
        }
    }
    
    func findUser(withAccount account: String, completion: @escaping ((_ result: Bool, _ userData: JSON?) -> Void)) {
        let findRef = ref.child(DBPathStrings.userDataPath)
        findRef.queryOrdered(byChild: DBPathStrings.accountPath).queryEqual(toValue: account).queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.value is NSNull {
                completion(false, nil)
                print("not find user...")
            } else {
                let json = JSON(snapshot.value ?? "not find")
                print("find user...")
                completion(true, json)
            }
        })
    }
    
    func addUserAsFriend(userID: String, result: Bool, friend: JSON?) {
        if result == false {
            // should show alert later.
        } else {
            if let json = friend {
                for (friendID, _) in json {
                    // should show friend info with a "adding" btn.
                    
                    /* add friendID into userID's friend list. */
                    let addRef = ref.child(DBPathStrings.friendDataPath).child(userID).child(friendID).child(DBPathStrings.friendTypePath)
                    addRef.setValue("PadiUser")
                    
                    /* add userID into friendID's friend list */
                    let mutualRef = ref.child(DBPathStrings.friendDataPath).child(friendID).child(userID).child(DBPathStrings.friendTypePath)
                    mutualRef.setValue("PadiUser")
                }
            }
        }
    }
    
    func getAttribute(for attribute: String, userID: String, completion: @escaping ((_ fetched: JSON) -> Void)) {
        let targetRef = ref.child(DBPathStrings.userDataPath).child(userID).child(attribute)
        targetRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            completion(json)
        })
    }
    
    func fetchFriendsList(userID: String, completion: @escaping ((_ list: [String]) -> Void)) {
        var list: [String] = []
        let friendRef = ref.child(DBPathStrings.friendDataPath).child(userID)
        friendRef.observe(.childAdded) { (snapshot) in
            if list.contains(snapshot.key) == false {
                list.append(snapshot.key)
                completion(list)
            }
        }
        
        friendRef.observe(.childRemoved) { (snapshot) in
            if list.contains(snapshot.key) == true {
                if let removeIndex = list.index(of: snapshot.key) {
                    list.remove(at: removeIndex)
                    completion(list)
                }
            }
        }
    }
}









