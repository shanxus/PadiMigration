//
//  PadiEvents.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/17.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

class PadiEvent {
    
    // MARK: - properties.
    private var eventName: String!
    private var eventID: String!
    private var eventImageURL: String!
    private var eventDateTimeInterval: TimeInterval!
    private var isFavorite: Bool!
    private var payCollection: [String]! = []
    private var memberCollection: [String]! = []
    
    init(withName name: String, ID: String, imageURL: String, date: TimeInterval, isFavorite: Bool, payCollection: [String], memberList: [String]) {
        self.eventName = name
        self.eventID = ID
        self.eventImageURL = imageURL
        self.eventDateTimeInterval = date
        self.isFavorite = isFavorite
        self.payCollection = payCollection
        self.memberCollection = memberList
    }
    
    // MARK: - getter methods.
    func getName() -> String {
        return self.eventName
    }
    
    func getID() -> String {
        return self.eventID
    }
    
    func getImageURLString() -> String {
        return self.eventImageURL
    }
    
    func getEventDateString() -> String {
        return EntityHelperClass.getPadiEntityDateString(with: self.eventDateTimeInterval)
    }
    
    func getTimeInterval() -> TimeInterval {
        return self.eventDateTimeInterval
    }
    
    func getIsFavorite() -> Bool {
        return self.isFavorite
    }
    
    func getPayCollectionID() -> [String] {
        return self.payCollection
    }
    
    func getPayCollectionCount() -> Int {
        return self.payCollection.count
    }
    
    func getMemberCollectionID() -> [String] {
        return self.memberCollection
    }
    
    func getMemberCollectionCount() -> Int {
        return self.memberCollection.count
    }
    
    // MARK: - setter methods.
    func setName(withNew name: String) {
        self.eventName = name
    }
    
    func setImageURLString(withNew string: String) {
        self.eventImageURL = string
    }
    
    func setTimeInterval(withNew time: TimeInterval) {
        self.eventDateTimeInterval = time
    }
    
    func setIsFavorite(withNew favorite: Bool) {
        self.isFavorite = favorite
    }
    
    func addPayCollectionID(with id: String) {
        self.payCollection.append(id)
    }
    
    func addMemberCollectionID(with id: String) {
        self.memberCollection.append(id)
    }
    
    func getEventTotalPay(userID: String, completion: @escaping((_ value: Float) -> Void)) {
        var total: Float = 0
        let dispatch = DispatchGroup()
        let helper = ExamplePay()
        
        for id in self.payCollection {
            dispatch.enter()
            helper.getPayValue(ofSinglePay: id, userID: userID, completion: { (value) in
                total += value
                dispatch.leave()
            })
        }
        
        dispatch.notify(queue: .main) { 
            completion(total)
        }
    }
}

class ExamplePadiEvent {
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    init() {
    }
    
    /*
    func getEvents(forSpecificUser path: String, completion: @escaping ((_ events: [PadiEvent]) -> Void)) {
        
        var exampleEvents: [PadiEvent] = []
        var memberlist: [String] = []
        var payList: [String] = []
        
        // in real app, there is one more level before the child(path).
        let eventRef = ref.child(DBPathStrings.eventDataPath).child(path)
        eventRef.queryOrdered(byChild: DBPathStrings.timePath).observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (key, value):(String, JSON) in json {
                
                // clear array.
                memberlist.removeAll()
                payList.removeAll()
                
                let id = key
                let url = value[DBPathStrings.imageURLPath].stringValue
                let isFavorite = value[DBPathStrings.isFavoritePath].stringValue == "true" ? true : false
                let members = value[DBPathStrings.memberListPath]
                for (_, memberID) in members {
                    memberlist.append(memberID.stringValue)
                }
                let name = value[DBPathStrings.namePath].stringValue
                let time = value[DBPathStrings.timePath].floatValue
                
                let examplePay = value[DBPathStrings.paysPath]
                for (_, payID) in examplePay {
                    let id = payID.stringValue
                    payList.append(id)
                }
                let newEvent = PadiEvent(withName: name, ID: id, imageURL: url, date: TimeInterval(time), isFavorite: isFavorite, payCollection: payList, memberList: memberlist)
                exampleEvents.append(newEvent)
            }            
            completion(exampleEvents)
        })
    }
   */
    
    /* listen events */
    func listenAdd(forSpecificUser path: String, completion: @escaping ((_ event: PadiEvent) -> Void)) {
        let eventRef = ref.child(DBPathStrings.eventDataPath).child(path)
        eventRef.observe(.childAdded, with: { (snapshot) in
            let eventID = snapshot.key
            self.getSingleEvent(withEventID: eventID, userID: path, completion: { (event) in
                completion(event)
            })
        })
    }
    
    /* listen added pays ID under event/userID/eventID */
    func listenPaysAdded(forEvent eventID: String, forUser userID: String, completion: @escaping ((_ payID: String) -> Void)) {
        let listenRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath)
        listenRef.observe(.childAdded, with: { (snapshot) in            
            let json = JSON(snapshot.value ?? "")
            completion(json.stringValue)
        })
    }
    
    func listenPaysRemoved(forEvent eventID: String, forUser userID: String, completion: @escaping ((_ payID: String) -> Void)) {
        let listenRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath)
        listenRef.observe(.childRemoved, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")            
            completion(json.stringValue)
        })
    }
    
    func getSingleEvent(withEventID id: String, userID: String, completion: @escaping ((_ event: PadiEvent) -> Void)) {
        var memberList: [String]! = []
        var payList: [String]! = []
        
        let eventRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(id)
        eventRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = JSON(snapshot.value ?? "")
            let url = value[DBPathStrings.imageURLPath].stringValue
            let isFavorite = value[DBPathStrings.isFavoritePath].stringValue == "true" ? true : false
            let members = value[DBPathStrings.memberListPath]
            for (_, memberID) in members {
                memberList.append(memberID.stringValue)
            }
            let name = value[DBPathStrings.namePath].stringValue
            let time = value[DBPathStrings.timePath].floatValue
            
            let examplePay = value[DBPathStrings.paysPath]
            for (_, payID) in examplePay {
                payList.append(payID.stringValue)
            }
            let newEvent = PadiEvent(withName: name, ID: id, imageURL: url, date: TimeInterval(time), isFavorite: isFavorite, payCollection: payList, memberList: memberList)
            completion(newEvent)
        })
    }
    
    func fetchAttribute(for attribute: String, eventID: String, userID: String, completion: @escaping((_ attribute: JSON) -> Void)) {
        let targetRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(attribute)
        targetRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            completion(json)
        }
    }
    
    func getMemberList(forSingleEvent event: String, userID: String, completion: @escaping ((_ memberList: [String]) -> Void)) {
        getSingleEvent(withEventID: event, userID: userID) { (event) in
            let memberList = event.getMemberCollectionID()
            completion(memberList)
        }
    }
    
    /* dynamically fetch the member list for a event. */
    func fetchMemberList(userID: String, eventID: String, completion: @escaping ((_ memberList: [String]) -> Void)) {
        let memberListRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.memberListPath)
        var memberList: [String] = []
        
        memberListRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (_, memberID) in json.dictionaryValue {
                if memberList.contains(memberID.stringValue) == false {
                    memberList.append(memberID.stringValue)
                }
            }
            completion(memberList)
        }
        
        memberListRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if memberList.contains(json.stringValue) == false {
                memberList.append(json.stringValue)
            }
            completion(memberList)
        }
        
        memberListRef.observe(.childRemoved) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if memberList.contains(json.stringValue) == true {
                if let removeIndex = memberList.index(of: json.stringValue) {
                    memberList.remove(at: removeIndex)
                }
            }
            completion(memberList)
        }
    }
    
    /* dynamically fetch the total pay value for a event. */
    func fetchTotalValue(userID: String, eventID: String, completion: @escaping ((_ value : Float) -> Void)) {
        let dispatch = DispatchGroup()
        var payList: [String:Float] = [:]
        
        /* Listen to .added in Event/UserID/EventID/pays to build the pay list. */
        let payHelper = ExamplePay()
        let payListRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath)
        payListRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            
            /* For each added pay, get its value. */
            let payID = json.stringValue
            dispatch.enter()
            payHelper.getPayValue(ofSinglePay: payID, userID: userID, completion: { (payValue: Float) in
                payList[payID] = payValue
                dispatch.leave()
            })
            dispatch.notify(queue: .main) {
                let accumulaor = self.payValueAccumulationWith(payList: payList)
                completion(accumulaor)
            }
        }
        
        /* Listen to .change in Pay/UserID to detect the change of pay. */
        let userPaysRef = ref.child(DBPathStrings.payDataPath).child(userID)
        userPaysRef.observe(.childChanged) { (snapshot) in
            
            let id = snapshot.key
            let json = JSON(snapshot.value ?? "")
            /* if the changed pay's ID matchs the one existed in payList, it means updating the total value for a event is
             * needed.
             */
            if payList[id] != nil {
                let newValue = payHelper.accumulateFromPaySnapshot(json)
                payList[id] = newValue
                
                /* re-accumulate the value. */
                let accumulaor = self.payValueAccumulationWith(payList: payList)
                completion(accumulaor)
            }
        }
        
        /* listen to .delete in Pay/UserID to detect the delete of pay. */
        userPaysRef.observe(.childRemoved) { (snapshot) in
            
            let id = snapshot.key
            if payList[id] != nil {
                payList[id] = nil
                
                /* re-accumulate the value. */
                let accumulaor = self.payValueAccumulationWith(payList: payList)
                completion(accumulaor)
            }
        }
    }
    
    func payValueAccumulationWith(payList: [String:Float]) -> Float {
        var accumulaor: Float = 0
        for (_, value) in payList {
            accumulaor += value
        }
        return accumulaor
    }
    
    /* dynamically fetch the url of event image. */
    func fetchEventImageURL(userID: String, eventID: String, completion: @escaping ((_ url: String) -> Void)) {
        let imageRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.imageURLPath)
        imageRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let url = json.string {
                completion(url)
            }
        }
        let eventRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID)
        eventRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.imageURLPath {
                let json = JSON(snapshot.value ?? "")
                if let url = json.string {
                    completion(url)
                }
            }
        }
    }
    
    /* dynamically fetch the count of pay for a event. */
    func fetchPayCount(userID: String, eventID: String, completion: @escaping ((_ count: Int) -> Void)) {
        let countRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath)
        var pays: [String] = []
        
        countRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (_, payID) in json.dictionaryValue {
                if pays.contains(payID.stringValue) == false {
                    pays.append(payID.stringValue)
                }
            }
            completion(pays.count)
        }
        
        countRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if pays.contains(json.stringValue) == false {
                pays.append(json.stringValue)
            }
            completion(pays.count)
        }
        
        countRef.observe(.childRemoved) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if pays.contains(json.stringValue) == true {
                if let removeIndex = pays.index(of: json.stringValue) {
                    pays.remove(at: removeIndex)
                }
            }
            completion(pays.count)
        }
    }
    
    /* dynamically fetch the name of an event. */
    func fetchEventName(userID: String, eventID: String, completion: @escaping ((_ name: String) -> Void)) {
        let nameRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.namePath)
        nameRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            completion(json.stringValue)
        }
        
        let eventRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID)
        eventRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.namePath {
                let json = JSON(snapshot.value ?? "")
                completion(json.stringValue)
            }
        }                
    }
    
    func fetchEventNameWithoutCreatorID(eventID: String, completion: @escaping ((_ name: String) -> Void)) {
        getEventCreatrorID(eventID: eventID) { (creatorID: String) in
            self.fetchEventName(userID: creatorID, eventID: eventID, completion: { (eventName: String) in
                completion(eventName)
            })
        }
    }
    
    func store(imgURL: String, eventID: String, userID: String) {
        let finalRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.imageURLPath)
        finalRef.setValue(imgURL)
    }
    
    func store(favorite: Bool, eventID: String, userID: String) {
        let finalRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.isFavoritePath)
        finalRef.setValue(favorite)
    }
    
    func store(members: [String], eventID: String, userID: String) {
        /* need to fetch the member list on the DB first. */
        let memberListRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.memberListPath)
        var arr: [String] = []
        memberListRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (_, id) in json {
                arr.append(id.stringValue)
            }
            
            /* member that be in DB but not in members means it had been removed. */
            for each in arr {
                let indexArr = each.components(separatedBy: "-")
                if let index = indexArr.first {
                    if members.contains(each) == false {
                        
                        /* remove member from event node. */
                        let removeRef = memberListRef.child(index)
                        removeRef.removeValue()
                        
                        /* remove from sharedEvents */
                        if each != userID {
                            guard let eventIndex = eventID.components(separatedBy: "-").first else {return}
                            let sharedEventsRef = self.ref.child(DBPathStrings.sharedEvents).child(each).child(eventIndex)
                            sharedEventsRef.removeValue()
                        }
                    }
                }
            }
        }
        
        for each in members {
            let indexArr = each.components(separatedBy: "-")
            if let index = indexArr.first {
                
                /* save member into event node. */
                let saveRef = memberListRef.child(index)
                saveRef.setValue(each)
                
                /* save into sharedEvents */
                if each != userID {
                    guard let eventIndex = eventID.components(separatedBy: "-").first else {return}
                    let sharedEventsRef = ref.child(DBPathStrings.sharedEvents).child(each).child(eventIndex)
                    sharedEventsRef.setValue(eventID)
                }
            }
        }
    }
    
    func store(name: String, eventID: String, userID: String) {
        let nameRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.namePath)
        nameRef.setValue(name)
    }
    
    func store(pays: [String], eventID: String, userID: String) {
        for (index, value) in pays.enumerated() {
            let finalRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath).child("\(index)")
            finalRef.setValue(value)
        }
    }
    
    func store(time: Double, eventID: String, userID: String) {
        let timeRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.timePath)
        timeRef.setValue(time)
    }
    
    func storeCreator(eventID: String, userID: String) {
        if let userIndex = userID.components(separatedBy: "-").first {
            let creatorRef = ref.child(DBPathStrings.eventCreator).child(eventID).child(userIndex)
            creatorRef.setValue(userID)
        }
    }
    
    func storeIntoDB(event: PadiEvent, userID: String) {
        let eventID = event.getID()
        
        store(imgURL: event.getImageURLString(), eventID: eventID, userID: userID)
        
        store(favorite: event.getIsFavorite(), eventID: eventID, userID: userID)
        
        store(members: event.getMemberCollectionID(), eventID: eventID, userID: userID)
        
        store(name: event.getName(), eventID: eventID, userID: userID)
        
        store(pays: event.getPayCollectionID(), eventID: eventID, userID: userID)
        
        store(time: event.getTimeInterval(), eventID: eventID, userID: userID)
        
        storeCreator(eventID: eventID, userID: userID)
    }
    
    func delete(userID: String, eventID: String) {
        
        let targetEventRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID)
        /* remove from sharedEvents node. */
        let memberListRef = targetEventRef.child(DBPathStrings.memberListPath)
        memberListRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (_, memberID) in json.dictionaryValue {
                if memberID.stringValue != userID {
                    if let removeEventIndex = eventID.components(separatedBy: "-").first {
                        let sharedEventsRef = self.ref.child(DBPathStrings.sharedEvents).child(memberID.stringValue).child(removeEventIndex)
                        sharedEventsRef.removeValue()
                    }
                }
            }
        }
        
        /* remove from current user node. */
        targetEventRef.removeValue()
        
        /* remove from eventCreator node. */
        let eventCreatorRef = ref.child(DBPathStrings.eventCreator).child(eventID)
        eventCreatorRef.removeValue()
        
        /* remove event image from Storage. */
        let helper = GeneralService()
        helper.deleteFromStorageBy(folderPath: DBPathStrings.eventImagePath, uid: eventID)
    }
    
    func fetchSharedEvents(userID: String, completion: @escaping ((_ list: [String]) -> Void)) {
        var list: [String] = []
        
        let targetRef = ref.child(DBPathStrings.sharedEvents).child(userID)        
        
        targetRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let id = json.string {
                if list.contains(id) == false {
                    list.append(id)
                    completion(list)
                }
            }
        }
        
        targetRef.observe(.childRemoved) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let id = json.string {
                if list.contains(id) == true {
                    if let removeIndex = list.index(of: id) {
                        list.remove(at: removeIndex)
                        completion(list)
                    }
                }
            }
        }
    }
    
    func getEventCreatrorID(eventID: String, completion: @escaping ((_ ID: String) -> Void)) {
        let creatorRef = ref.child(DBPathStrings.eventCreator).child(eventID)
        creatorRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (id, _) in json.dictionaryValue {
                completion(id)
            }
        }
    }
    
    func fetchSharedEventName(eventID: String, completion: @escaping ((_ name: String) -> Void)) {
        getEventCreatrorID(eventID: eventID) { (ID: String) in
            self.fetchEventName(userID: ID, eventID: eventID, completion: { (name: String) in
                completion(name)
            })
        }
    }
    
    func fetchSharedEventImageURL(eventID: String, completion: @escaping ((_ url: String) -> Void)) {
        getEventCreatrorID(eventID: eventID) { (ID: String) in
            self.fetchEventImageURL(userID: ID, eventID: eventID, completion: { (url) in
                completion(url)
            })
        }
    }
}













