//
//  PayPayer.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/28.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import FirebaseDatabase

final class PayPayer: PayInvolvedMember {
    var payValue: Float!
    var isInvolved: Bool!
    
    init(withPayValue value: Float, ID: String, isInvolved: Bool) {
        super.init(with: ID)
        self.payValue = value
        self.isInvolved = isInvolved
    }
    
    init(id: String, info: JSON) {
        super.init(with: id)
        self.payValue = info[DBPathStrings.value].floatValue
        self.isInvolved = info[DBPathStrings.isInvolved].boolValue
    }
    
    func getAttribute(for attribute: String, completion: @escaping ((_ fetched: JSON) -> Void)) {
        let ref = Database.database().reference()
        let targetRef = ref.child(DBPathStrings.userDataPath).child(self.ID).child(attribute)
        targetRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            completion(json)
        })
    }
}

final class PayPayee: PayInvolvedMember {
    var valueShouldPay: Float!
    var shouldGiveTo: String!
    
    init(withValueShouldPay value: Float = 0, ID: String, shouldGiveTo payerID: String) {
        super.init(with: ID)
        self.valueShouldPay = value
        self.shouldGiveTo = payerID
    }
    
    func getAttribute(for attribute: String, completion: @escaping ((_ fetched: JSON) -> Void)) {
        let ref = Database.database().reference()
        let targetRef = ref.child(DBPathStrings.userDataPath).child(self.ID).child(attribute)
        targetRef.observeSingleEvent(of: .value, with: { (snapshot) in
            let json = JSON(snapshot.value ?? "")
            completion(json)
        })
    }
    
}

final class PersonalPay {
    var id: String!
    var payerID: String!
    var belongsToMember: String!
    var value: Float!
    
    init(withID ID:String , Payer payerID: String, belongsTo payeeID: String, value: Float) {
        self.id = ID
        self.payerID = payerID
        self.belongsToMember = payeeID
        self.value = value
    }
    
    init(id: String, info: JSON) {
        self.id = id
        self.payerID = info[DBPathStrings.payerPath].stringValue
        self.belongsToMember = info[DBPathStrings.belongsTo].stringValue
        self.value = info[DBPathStrings.value].floatValue
    }
}

extension PayPayer: CustomStringConvertible {
    var description: String {
        
        let beginningDes = "This is a PayPayer Object with following descriptions: \n"
        
        var payer = ""
        if let _payer = self.ID {
            payer = "payer ID: \(_payer) \n"
        }
        
        var value = ""
        if let _value = self.payValue {
            value = "pay value: \(_value) \n"
        }
        
        let involved = (self.isInvolved==true) ? "isInvolved: true \n" : "isInvolved: false \n\n"
        
        return beginningDes + payer + value + involved
    }
}

extension PayPayee: CustomStringConvertible {
    var description: String {
        
        let beginningDes = "This is a PayPayee Object with following descriptions: \n"
        
        var payee = ""
        if let _payee = self.ID {
            payee = "payee ID: \(_payee) \n"
        }
        
        var value = ""
        if let _value = self.valueShouldPay {
            value = "value should pay: \(_value) \n"
        }
        
        var payer = ""
        if let _payer = self.shouldGiveTo {
            payer = "payer ID: \(_payer) \n\n"
        }
        
        return beginningDes + payee + value + payer
    }
}

extension PersonalPay: CustomStringConvertible {
    var description: String {

        let beginningDes = "This is a PersonalPay Object with following descriptions: \n"
        
        var idDes = ""
        if let _idDes = self.id {
            idDes = "id: \(_idDes) \n"
        }
        
        var payer = ""
        if let _payer = self.payerID {
            payer = "payer ID: \(_payer) \n"
        }
        
        var belongsTo = ""
        if let _belongsTo = self.belongsToMember {
            belongsTo = "belongs to: \(_belongsTo) \n"
        }
        
        var value = ""
        if let _value = self.value {
            value = "value should pay: \(_value) \n"
        }
        
        return beginningDes + idDes + payer + belongsTo + value
    }
}

extension PayPayer: Equatable {
    static func == (lhs: PayPayer, rhs: PayPayer) -> Bool {
        return lhs.ID == rhs.ID && lhs.payValue == rhs.payValue && lhs.isInvolved == rhs.isInvolved
    }
}

extension PayPayee: Equatable {
    static func == (lhs: PayPayee, rhs: PayPayee) -> Bool {
        return lhs.ID == rhs.ID && lhs.shouldGiveTo == rhs.shouldGiveTo && lhs.valueShouldPay == rhs.valueShouldPay
    }
}

extension PersonalPay: Equatable {
    static func == (lhs: PersonalPay, rhs: PersonalPay) -> Bool {
        return lhs.id == rhs.id && lhs.payerID == rhs.payerID && lhs.belongsToMember == rhs.belongsToMember && lhs.value == rhs.value
    }
}










