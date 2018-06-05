//
//  PadiPay.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/18.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON

enum payShareMode: String {
    case sharedPay = "均分"
    case notSharedPay = "不均分"
    case notSet = "尚未設定"
}

enum payRefund {
    case refunded
    case notRefunded
}

enum serviceCharge {
    case charged
    case notCharged
}

class PadiPay {
    
    let exampleDataPath = "examplePayData"
    
    // MARK: properties.
    private var id: String = ""
    private var belongsToEventId: String!
    private var name: String!
    private var imageURL: String!
    private var dateTimeInterval: TimeInterval!
    private var membersList: [String]! = []
    private var payRelationshipTable: [PayRelation] = []
    
    /*
     This is a computed property for calculating the value of pay.
     What it returns depends on isServiceCharged.
     */
    private var totalPayValue: Float! {
        if self.isServiceCharged == true {
            return basePayValue + (basePayValue * serviceChargeValue/100)
        } else {
            return basePayValue
        }
    }
    
    /*
     This property stores the value of pay for this pay object.
     */
    private var basePayValue: Float! {
        return payerPayValue
    }
    
    /*
     This property is used to store how much value the payers pay.
     */
    private var payerPayValue: Float! {
        var accumulator: Float = 0
        for payer in self.payer {
            accumulator += payer.payValue
        }
        return accumulator
    }
    
    /**
     This property is used to store how much value the payee should pay.
     */
    private var payeePayValue: Float! {
        let payeeShouldPay: Float = self.getTotalPayValue() / Float(self.getPayeeCount())
        return payeeShouldPay
    }

    
    private var serviceChargeValue: Float!
    private var isServiceCharged: Bool! {
        didSet {
            if isServiceCharged == false {
                serviceChargeValue = 0
            }
        }
    }
    
    // support the functionality of refund calculating in future.
    //var refund: payRefund! = payRefund.notRefunded
    
    private var payer: [PayPayer]! = []
    private var payee: [PayPayee]! = []
    private var personalPays: [PersonalPay]! = []
    
    /**
     Init function.
     Parameter image has its default value.
     */
    
    init(payID ID: String, belongsToEventID eventID: String, name: String, imageURL: String, dateTimeInterval: TimeInterval, memberList: [String], isServiceCharged: Bool, serviceChargeValue: Float, payerList: [PayPayer], payeeList: [PayPayee], personalPayList: [PersonalPay]) {
        
        self.id = ID
        self.belongsToEventId = eventID
        self.name = name
        self.imageURL = imageURL
        self.dateTimeInterval = dateTimeInterval
        self.membersList = memberList
        self.isServiceCharged = isServiceCharged
        self.serviceChargeValue = serviceChargeValue
        self.payer = payerList
        self.payee = payeeList
        self.personalPays = personalPayList
    }        
    
    // MARK: - getter methods.
    func getDateString() -> String {
        return EntityHelperClass.getPadiEntityDateString(with: self.dateTimeInterval)
    }
    
    func getID() -> String {
        return self.id
    }
    
    func getBelongsToEventID() -> String {
        return self.belongsToEventId
    }
    
    func getName() -> String {
        return self.name
    }
    
    func getImageURLString() -> String {
        return self.imageURL
    }
    
    func getTimeIntervale() -> TimeInterval {
        return self.dateTimeInterval
    }
    
    func getMemberList() -> [String] {
        return membersList
    }
    
    func getRelationalTable() -> [PayRelation] {
        return self.payRelationshipTable
    }
    
    func getPayerCount() -> Int {
        return payer.count
    }
    
    func getPayeeCount() -> Int {
        return payee.count
    }
    
    func getPersonalPayCount() -> Int {
        return self.personalPays.count
    }
    
    func getTotalPayValue() -> Float {
        return totalPayValue
    }
    
    func getBasePayValue() -> Float {
        return self.basePayValue
    }
    
    func getPayerPayValue() -> Float {
        return self.payerPayValue
    }
    
    func getPayeePayValue() -> Float {
        return self.payeePayValue
    }
    
    func getServiceChargeValue() -> Float {
        return self.serviceChargeValue
    }
    
    func getIsServiceCharged() -> Bool {
        return self.isServiceCharged
    }
    
    func getPayers() -> [PayPayer] {
        return self.payer
    }
    
    func getPayees() -> [PayPayee] {
        return self.payee
    }
    
    func getPersonalPay() -> [PersonalPay] {
        return self.personalPays
    }
    
    // MARK: - setter methods.
    func setPayDate(withTimeInterval interval: String) {
        if let intervalDouble = Double(interval) {
            self.dateTimeInterval = intervalDouble
        }
    }
    
    fileprivate func setPayID(withID id: String) {
        self.id = id
    }
    
    func setBelongsToEventID(withID id: String) {
        self.belongsToEventId = id
    }
    
    func setPayName(withName name: String) {
        self.name = name
    }
    
    func setPayImageURL(withNew url: String) {
        self.imageURL = url
    }
    
    func setPayMemberList(withMemberList memberLis: [String]) {
        self.membersList = memberLis
    }
    
    func setIsServiceCharged(withValue value: Bool) {
        self.isServiceCharged = value
    }
    
    func setServiceChargeValue(withValue value: Float) {
        self.serviceChargeValue = value
    }
    
    func setPayers(withPayers payers: [PayPayer]) {
        self.payer = payers
    }
    
    func addPayer(with payer: PayPayer) {
        self.payer.append(payer)
    }
    
    func addPayee(with payee: PayPayee) {
        self.payee.append(payee)
    }
    
    func addPersonalPay(with pay: PersonalPay) {
        self.personalPays.append(pay)
    }
    
    func removePayer(in index: Int) {
        self.payer.remove(at: index)
    }
    
    func removePayee(in index: Int) {
        self.payee.remove(at: index)
    }
    
    func removePersonalPay(in index: Int) {
        self.personalPays.remove(at: index)
    }
    
    func setPayees(withPayees payees: [PayPayee]) {
        self.payee = payees
    }
    
    func setPersonalPays(withPersonalPays pays: [PersonalPay]) {
        self.personalPays = pays
    }
}

extension PadiPay {
    
    /**
     This function detects whether a member is already existed in the payer array.
     */
    func doesPayerAlreadyExist(withID ID: String) -> Bool {
        var appear: Bool = false
        for payer in self.getPayers() {
            if payer.ID == ID {
                appear = true
            }
        }
        return appear
    }

    /**
     This function detects whether a member is already existed in the payee array.
     */
    func doesMemberExistInPayeeList(withID ID: String, isPayer: Bool) -> Bool {
        var appear: Bool = false
        if isPayer == true {
            for eachRecord in self.getPayees() {
                if eachRecord.shouldGiveTo == ID {
                    appear = true
                }
            }
        } else {
            for eachRecord in self.getPayees() {
                if eachRecord.ID == ID {
                    appear = true
                }
            }
        }
        return appear
    }
    
    /**
     This function detects whether a member is already existed in the personalPay array.
     */
    func doesMemberExistInPersonalPay(withID ID: String, isPayer: Bool) -> Bool {
        var appear: Bool = false
        
        if isPayer == true {
            for eachPayer in self.getPersonalPay() {
                if eachPayer.payerID == ID {
                    appear = true
                }
            }
        } else {
            for eachPayee in self.getPersonalPay() {
                if eachPayee.belongsToMember == ID {
                    appear = true
                }
            }
        }
        
        return appear
    }
    
    /**
     This function adds a member into the payer array.
     */
    func addNewPayer(withID ID: String, value: Float, isInvolved: Bool, handler:  ((_ payID: String, _ payerID: String, _ value: Float, _ eventID: String) -> Void)?) {
        if self.doesPayerAlreadyExist(withID: ID) == false {
            let payer = PayPayer(withPayValue: value, ID: ID, isInvolved: isInvolved)
            self.addPayer(with: payer)    
        }
        if let _handler = handler {
            _handler(self.getID(), ID, value, self.getBelongsToEventID())
        }
        
    }
    
    /**
     This function adds a member into the payee array.
     */
    func addNewPayee(withID ID: String, payTo payerID: String, withValueShouldPay value: Float = 0, handler: ((_ payID: String, _ payeeID: String, _ value: Float, _ eventID: String) -> Void)?) {
        
        let payee = PayPayee(withValueShouldPay: value, ID: ID, shouldGiveTo: payerID)
        self.addPayee(with: payee)
        
        if let _handler = handler {
            _handler(self.getID(), ID, self.getPayeePayValue(), self.getBelongsToEventID())
        }
    }
    
    /**
     This function removes a member which is also a payer.
     */
    func removeAPayer(withID ID: String, handler: ((_ payerID: String, _ payID: String, _ eventID: String) -> Void)?) {
        
        var indexList: [Int] = []
        var offset = 0
        
        // remove from payer array.
        indexList = self.findPayerInPayerArray(withID: ID)
        
        for index in indexList {
            self.removePayer(in: index - offset)
            offset += 1
        }
        
        // remove payees that should pay to that payer.
        indexList = self.findMemberInPayeeArray(withID: ID, isPayer: true)
        offset = 0
        
        for index in indexList {
            self.removePayee(in: index - offset)
            offset += 1
        }
        
        // remove perosnal pays that paid by that payer.
        indexList = self.findMemberInPersonalPayArray(withID: ID, isPayer: true)
        offset = 0
        
        for index in indexList {
            self.removePersonalPay(in: index - offset)
            offset += 1
        }
        
        if let _handler = handler {
            _handler(ID, self.getID(), self.getBelongsToEventID())
        }
    }
    
    /**
     This function removes a member which is also a payee.
     */
    func removeAPayee(withID ID: String, handler: ((_ payeeID: String, _ payID: String, _ eventID: String) -> Void)?) {
        
        var indexList: [Int] = []
        var offset = 0
        
        // remove from payee array.
        indexList = self.findMemberInPayeeArray(withID: ID, isPayer: false)
        
        for index in indexList {
            self.removePayee(in: index - offset)
            offset += 1
        }
        
        // remove from personalPay array.
        indexList = self.findMemberInPayeeArray(withID: ID, isPayer: false)
        offset = 0
        
        for index in indexList {            
            self.removePersonalPay(in: index - offset)
            offset += 1
        }
        
        if let _handler = handler {
            _handler(ID, self.getID(), self.getBelongsToEventID())
        }
        
    }
    
    /**
     This function adds a personal pay into the personalPay array.
    */
    func addNewPersonalPay(withID ID: String, payerID: String, belongsToMemberID: String, value: Float) {
        let newPersonalPayObj = PersonalPay(withID: ID, Payer: payerID, belongsTo: belongsToMemberID, value: value)
        self.addPersonalPay(with: newPersonalPayObj)
    }
    
    func findPayerInPayerArray(withID ID: String) -> [Int] {
        
        var indexes: [Int] = []
        var index = 0
        
        for eachPayer in self.getPayers() {
            if eachPayer.ID == ID {
                indexes.append(index)
            }
            index += 1
        }
        
        return indexes
    }
    
    /**
     This function finds the indexes of a member existed in the payee array.
     */
    func findMemberInPayeeArray(withID ID: String, isPayer: Bool) -> [Int] {
        var indexes: [Int] = []
        
        if isPayer == true {
            var index = 0
            for eachPayee in self.getPayees() {
                if eachPayee.shouldGiveTo == ID {
                    indexes.append(index)
                }
                index += 1
            }
        } else {
            var index = 0
            for eachPayee in self.getPayees() {
                if eachPayee.ID == ID {
                    indexes.append(index)
                }
                index += 1
            }
        }
        
        return indexes
    }
    
    /**
     This function finds the indexes of a member existed in the payee array.
     */
    func findMemberInPersonalPayArray(withID ID: String, isPayer: Bool) -> [Int] {
        var indexes: [Int] = []
        
        if isPayer == true {
            var index = 0
            
            for eachPersonalPay in self.getPersonalPay() {
                if eachPersonalPay.payerID == ID {
                    indexes.append(index)
                }
                index += 1
            }
        } else {
            var index = 0
            
            for eachPersonalPay in self.getPersonalPay() {
                if eachPersonalPay.belongsToMember == ID {
                    indexes.append(index)
                }
                index += 1
            }
        }
        
        return indexes
    }
}

extension PadiPay: CustomStringConvertible {
    var description: String {
        
        let beginningDes = "This is a PadiPay Object with following descriptions: \n"
        
        let idDes = self.getID()
        
        let belongsToEventIdDes = "Belongs to event ID: \(self.getBelongsToEventID()) \n"
        
        let nameDes = "Pay name: \(self.getName()) \n"
        
        let imageURLDes = "Image URL: \(self.getImageURLString()) \n"
        
        let dateDes = "Date: \(EntityHelperClass.getPadiEntityDateString(with: self.getTimeIntervale())) \n"
        
        // let PadiMember conform to CustomStringConvertible later.
        let memberListDes = "Member list count: \(self.getMemberList().count) \n"
        
        let totalPayValueDes = "Total pay value: \(self.getTotalPayValue()) \n"
        
        let basePayValueDes = "Base pay value: \(self.getBasePayValue()) \n"
        
        let payerPayValueDes = "Total payer pay value: \(self.getPayerPayValue()) \n"
        
        let isServiceChargedDes = (self.getIsServiceCharged() == true) ? "This pay has service charge. \n" : "This pay has not service charge. \n"
        
        let serviceChargeValueDes = "Service charge value: \(self.getServiceChargeValue()) \n"
        
        // let PayPayer conform to CustomStringConvertible later.
        let payerListDes = "Payer list count: \(self.getPayerCount()) \n\n"
        
        // let PayPayee conform to CustomStringConvertible later.
        let payeeListDes = "Payee list count: \(self.getPayeeCount()) \n"
        
        // let PersonalPay conform to CustomStringConvertible later.
        let personalPayDes = "Personal pay list count: \(self.getPersonalPayCount()) \n"
        
        return beginningDes + idDes + belongsToEventIdDes + nameDes + imageURLDes + dateDes + memberListDes + totalPayValueDes + basePayValueDes + payerPayValueDes + isServiceChargedDes + serviceChargeValueDes + payerListDes + payeeListDes + personalPayDes
    }
}

class ExamplePay {
    var ref: DatabaseReference! {
        return Database.database().reference()
    }
    
    init() {}
    
    /* get total pay value of a pay, including shared pays, perosnal pays and service charge.
     * note: this is .value single observer.
     */
    func getPayValue(ofSinglePay id: String, userID: String, completion: @escaping((_ value: Float) -> Void)) {
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(id)
        let payerRef = payRef.child(DBPathStrings.payerPath)
        let ppRef = payRef.child(DBPathStrings.ppPath)
        
        let dispatch = DispatchGroup()
        
        var payersArr: [PayPayer] = []
        var ppsArr: [PersonalPay] = []
        
        dispatch.enter()
        payerRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (id, info) in json.dictionaryValue {
                let newPayer = PayPayer(id: id, info: info)
                if payersArr.contains(newPayer) == false {
                    payersArr.append(newPayer)
                }
            }
            dispatch.leave()
        }
        
        dispatch.enter()
        ppRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (id, info) in json.dictionaryValue {
                let newPP = PersonalPay(id: id, info: info)
                if ppsArr.contains(newPP) == false {
                    ppsArr.append(newPP)
                }
            }
            dispatch.leave()
        }
        
        dispatch.notify(queue: .main) {
            let accumulator = self.accumulateFrom(payersArr: payersArr, ppsArr: ppsArr)
            completion(accumulator)
        }
    }
    
    func accumulateFrom(payersArr: [PayPayer], ppsArr: [PersonalPay]) -> Float {
        var acc: Float = 0
        
        for payer in payersArr {
            acc += payer.payValue
        }
        
        for pp in ppsArr {
            acc += pp.value
        }
        
        return acc
    }
    
    func accumulateFromPaySnapshot(_ snapshot: JSON) -> Float {
        var accumulator: Float = 0
        
        let payers = snapshot[DBPathStrings.payerPath].dictionaryValue
        /* accumulate shared pay. */
        for (_, info) in payers {
            accumulator += info[DBPathStrings.value].floatValue
        }
        
        /* accumulate personal pay. */
        let pps = snapshot[DBPathStrings.ppPath].dictionaryValue
        for (_, info) in pps {
            let value = info[DBPathStrings.value].floatValue
            accumulator += value
        }
        
        let serviceChargeValue = snapshot[DBPathStrings.serviceChargePath].floatValue
        if serviceChargeValue != 0 {
            accumulator = accumulator + (accumulator * serviceChargeValue/100)
        }
        
        return accumulator
    }
    
    func fetchPayValue(userID: String, payID: String, completion: @escaping ((_ value: Float) -> Void)) {
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        var sharedPayers: [PayPayer] = []
        var pps: [PersonalPay] = []
        
        payRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            for (key, info) in json.dictionaryValue {
                if key == DBPathStrings.ppPath {
                    for (ppID, detail) in info.dictionaryValue {
                        let newPP = PersonalPay(id: ppID, info: detail)
                        if pps.contains(newPP) == false {
                            pps.append(newPP)
                        }
                    }
                } else if key == DBPathStrings.payerPath {
                    for (payerID, detail) in info.dictionaryValue {                        
                        let newPayer = PayPayer(id: payerID, info: detail)
                        if sharedPayers.contains(newPayer) == false {
                            sharedPayers.append(newPayer)
                        }
                    }
                }
            }
            let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr:pps)
            completion(value)
        }
        
        let ppRef = payRef.child(DBPathStrings.ppPath)
        /* listen to add of pp. */
        ppRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let newPP = PersonalPay(id: snapshot.key, info: json)
            if pps.contains(newPP) == false {
                pps.append(newPP)
                let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr:pps)
                completion(value)
            }
        }
        /* listen to delete of pp. */
        ppRef.observe(.childRemoved) { (snapshot) in
            let removeID = snapshot.key
            for each in pps {
                if each.id == removeID {
                    if let removeIndex = pps.index(of: each) {
                        pps.remove(at: removeIndex)
                        let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr:pps)
                        completion(value)
                        break
                    }
                }
            }
        }
        /* listen to change of pp. */
        ppRef.observe(.childChanged) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let changedPP = PersonalPay(id: snapshot.key, info: json)
            for each in pps {
                if each.id == changedPP.id {
                    each.value = changedPP.value
                    let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr:pps)
                    completion(value)
                    break
                }
            }
        }
        
        let payerRef = payRef.child(DBPathStrings.payerPath)
        /* listen to add of payer. */
        payerRef.observe(.childAdded) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let newPayer = PayPayer(id: snapshot.key, info: json)
            if sharedPayers.contains(newPayer) == false {
                sharedPayers.append(newPayer)
                let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr: pps)
                completion(value)
            }
        }
        /* listen to remove of payer. */
        payerRef.observe(.childRemoved) { (snapshot) in
            let removedID = snapshot.key
            for (index, each) in sharedPayers.enumerated() {
                if each.ID == removedID {
                    sharedPayers.remove(at: index)
                    break
                }
            }
            let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr: pps)
            completion(value)
        }
        /* listen to change of payer. */
        payerRef.observe(.childChanged) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let changedValue = json[DBPathStrings.value].float {
                let changedID = snapshot.key
                
                for (index, each) in sharedPayers.enumerated() {
                    if each.ID == changedID {
                        sharedPayers[index].payValue = changedValue
                        break
                    }
                }
                let value = self.accumulateFrom(payersArr: sharedPayers, ppsArr: pps)
                completion(value)
            }
        }
    }
    
    /* dynamically fetch the image of pay. */
    func fetchPayImage(payID: String, userID: String, completion: @escaping ((_ imageURL: String) -> Void)) {
        let imageRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.imageURLPath)
        imageRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let url = json.string {
                completion(url)
            }
        }
        
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.imageURLPath {
                let json = JSON(snapshot.value ?? "")
                if let url = json.string {
                    completion(url)
                }
            }
        }
    }
    
    /* dynamically fetch the default image of pay. */
    func fetchPayDefaultImageType(payID: String, userID: String, completion: @escaping ((_ type: String) -> Void)) {
        let imageRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.imageURLPath)
        imageRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let type = json.string {
                completion(type)
            }
        }
        
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.imageURLPath {
                let json = JSON(snapshot.value ?? "")
                if let type = json.string {
                    completion(type)
                }
            }
        }
    }
    
    /* dynamically fetch the name of pay. */
    func fetchPayName(payID: String, userID: String, completion: @escaping ((_ name: String) -> Void)) {
        let nameRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.namePath)
        nameRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let name = json.string {
                completion(name)
            }
        }
        
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.namePath {
                let json = JSON(snapshot.value ?? "")
                if let name = json.string {
                    completion(name)
                }
            }
        }
    }
    
    /* dynamically fetch the service charge value of a pay. */
    func fetchServiceChargeValue(payID: String, userID: String, completion: @escaping ((_ serviceChargeValue: Float) -> Void)) {
        let serviceChargeRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.serviceChargePath)
        serviceChargeRef.observeSingleEvent(of: .value) { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            if let value = json.float {
                completion(value)
            }
        }
        
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payRef.observe(.childChanged) { (snapshot) in
            if snapshot.key == DBPathStrings.serviceChargePath {
                let json = JSON(snapshot.value ?? "")
                if let value = json.float {
                    completion(value)
                }
            }
        }
    }
    
    /* dynamically fetch the member list for a pay. */
    func fetchMemberList(payID: String, userID: String, completion: @escaping ((_ memberList: [String]) -> Void)) {
        let memberListRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.memberListPath)
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
    
    func fetchPayAttribute(for attribute: String, payID: String, userID: String, completion: @escaping((_ attribute: JSON) -> Void)) {
        let payRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            let returnValue = json[attribute]
            completion(returnValue)
        })
    }
    
    func store(payees: [PayPayee], payID: String, userID: String) {
        for each in payees {
            let finalRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payeePath).child(each.ID).child(each.shouldGiveTo)
            finalRef.setValue(0)
        }
    }
    
    func update(payees: [PayPayee], payID: String, userID: String) {
        let targetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payeePath)
        targetRef.removeValue()
        store(payees: payees, payID: payID, userID: userID)
    }
    
    func store(payers: [PayPayer], payID: String, userID: String) {
        for each in payers {
            let targetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payerPath).child(each.ID)
            targetRef.setValue(["\(DBPathStrings.isInvolved)":each.isInvolved,
                                "\(DBPathStrings.value)":each.payValue])                        
        }
    }
    
    func update(payers: [PayPayer], payID: String, userID: String) {
        let targetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.payerPath)
        targetRef.removeValue()
        store(payers: payers, payID: payID, userID: userID)
    }
    
    func store(personalPay: [PersonalPay], payID: String, userID: String) {
        for each in personalPay {
            let targetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.ppPath).child(each.id)
            targetRef.setValue(["\(DBPathStrings.belongsTo)":each.belongsToMember,
                                   "\(DBPathStrings.payerPath)":each.payerID,
                                   "\(DBPathStrings.value)":each.value])
        }
    }
    
    func update(personalPay: [PersonalPay], payID: String, userID: String) {        
        store(personalPay: personalPay, payID: payID, userID: userID)
    }
    
    func delete(personalPayID: String, payID: String, userID: String) {
        let targetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.ppPath).child(personalPayID)
        targetRef.removeValue()
    }
    
    func store(imgURL: String, payID: String, userID: String) {
        let imgRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.imageURLPath)
        imgRef.setValue(imgURL)
    }
    
    func store(imageType: String, payID: String, userID: String) {
        let imgRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.imageURLPath)
        imgRef.setValue(imageType)
    }
    
    func store(isCharged: Bool, payID: String, userID: String) {
        let isChargedRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.isServiceChargedPath)
        isChargedRef.setValue(isCharged)
    }
    
    func store(members: [String], payID: String, userID: String) {
        for (index, value) in members.enumerated() {
            let memberListRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.memberListPath).child("\(index)")
            memberListRef.setValue(value)
        }
    }
    
    func store(name: String, payID: String, userID: String) {
        let nameRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.namePath)
        nameRef.setValue(name)
    }
    
    func store(serviceCharge: Float, payID: String, userID: String) {
        let serRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.serviceChargePath)
        serRef.setValue(serviceCharge)
    }
    
    func store(time: Double, payID: String, userID: String) {
        let timeRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID).child(DBPathStrings.timePath)
        timeRef.setValue(time)
    }
    
    func storeIntoDB(pay: PadiPay, userID id: String) {
        let payID = pay.getID()
        
        /* stored under pay/userID */
        store(imgURL: pay.getImageURLString(), payID: payID, userID: id)
        
        store(isCharged: pay.getIsServiceCharged(), payID: payID, userID: id)
        
        store(members: pay.getMemberList(), payID: payID, userID: id)
        
        store(name: pay.getName(), payID: payID, userID: id)
        
        store(payees: pay.getPayees(), payID: payID, userID: id)
        
        store(payers: pay.getPayers(), payID: payID, userID: id)
        
        store(personalPay: pay.getPersonalPay(), payID: payID, userID: id)
        
        store(serviceCharge: pay.getServiceChargeValue(), payID: payID, userID: id)
        
        store(time: pay.getTimeIntervale(), payID: payID, userID: id)
        
        /* stored under event/userID/eventID/pays */
        storeIntoEventNode(userID: id, eventID: pay.getBelongsToEventID(), newPayID: pay.getID())
    }
    
    func storeIntoEventNode(userID: String, eventID: String, newPayID: String) {
        let arr = newPayID.components(separatedBy: "-")
        if let key = arr.first {
            let targetRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath).child(key)
            targetRef.setValue(newPayID)
        }
    }
    
    func removeFromDB(userID: String, eventID: String, payID: String) {
        /* removed from event/userID/eventID/pays/prefixOFPayID */
        let arr = payID.components(separatedBy: "-")
        if let key = arr.first {
            let eventNodeTargetRef = ref.child(DBPathStrings.eventDataPath).child(userID).child(eventID).child(DBPathStrings.paysPath).child(key)
            eventNodeTargetRef.removeValue()
            // should handle remove error.
        }
        
        /* removed from pay/userID/payID */
        let payNodeTargetRef = ref.child(DBPathStrings.payDataPath).child(userID).child(payID)
        payNodeTargetRef.removeValue()
        // should handle remove error.
        
        /* remove pay image from Storage. */
        let helper = GeneralService()
        helper.deleteFromStorageBy(folderPath: DBPathStrings.payImagePath, uid: payID)
    }
}














