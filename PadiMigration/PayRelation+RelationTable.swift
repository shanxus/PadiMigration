//
//  payRelation.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/6.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation

final class RelationTable {
    
    func buildTable(memberList: [String], payers: [PayPayer], payees: [PayPayee], personalPays: [PersonalPay]) -> [[Float]] {
        let length = memberList.count
        var table = Array(repeating: Array(repeating: Float(0), count: length), count: length)
        let sortedList = memberList.sorted()
        
        /* shared pays */
        for payer in payers {
            guard let payerIndex = sortedList.index(of: payer.ID) else {return table}
            
            var payeesThatShouldBeUpdated: [PayPayee] = []
            for payee in payees {
                /* if payee ID equals to payer ID, then not accumulate. */
                if payee.shouldGiveTo == payer.ID, payee.ID != payer.ID {
                    payeesThatShouldBeUpdated.append(payee)
                }
            }
            
            var sharedCount = payeesThatShouldBeUpdated.count
            if sharedCount != 0 {
                
                /* check whether a payer is involved. */
                sharedCount = payer.isInvolved == true ? sharedCount + 1 : sharedCount
                let sharedValue = payer.payValue / Float(sharedCount)
                
                /* find index and add records into table. */
                for appendedPayee in payeesThatShouldBeUpdated {
                    guard let payeeIndex = sortedList.index(of: appendedPayee.ID) else {return table}
                    table[payeeIndex][payerIndex] += sharedValue.rounded()
                }
            }
        }
        
        /* personal pays */
        for pp in personalPays {
         
            guard let payerID = pp.payerID else {return table}
            guard let payeeID = pp.belongsToMember else {return table}
            guard let value = pp.value else {return table}
            
            guard let payerIndex = sortedList.index(of: payerID) else {return table}
            guard let payeeIndex = sortedList.index(of: payeeID) else {return table}
            
            table[payeeIndex][payerIndex] += value
            
        }
        return table
    }
    
    func transformIntoRelation(relationTable: [[Float]], memberList: [String]) -> [PayRelation] {
        var relation: [PayRelation] = []
        let length = memberList.count
        
        var mutableRelationTable = relationTable
        
        if relationTable.count == length {
            let sortedList = memberList.sorted()
            
            /* accumulate values. */
            for rowIndex in 0..<length {
                for columnIndex in (rowIndex+1)..<length {
                    mutableRelationTable[rowIndex][columnIndex] += ((-1) * (mutableRelationTable[columnIndex][rowIndex]))
                }
            }
            
            /* transform into relation. */
            for rowIndex in 0..<length {
                for columnIndex in (rowIndex+1)..<length {
                    let value = mutableRelationTable[rowIndex][columnIndex]
                    if value > 0 {
                        let payerID = sortedList[columnIndex]
                        let payeeID = sortedList[rowIndex]
                        let newRelation = PayRelation(payerID: payerID, payeeID: payeeID, value: value)
                        relation.append(newRelation)
                    } else if value == 0 {
                        // nothing to do.
                    } else {
                        let payerID = sortedList[rowIndex]
                        let payeeID = sortedList[columnIndex]
                        let newRelation = PayRelation(payerID: payerID, payeeID: payeeID, value: (value * (-1)) )
                        relation.append(newRelation)
                    }
                }
            }
        }
        return relation
    }
}

final class PayRelation {
    var payerID: String?
    var payeeID: String?
    var valueShouldPay: Float?
    
    init(payerID: String, payeeID: String, value: Float) {
        self.payerID = payerID
        self.payeeID = payeeID
        self.valueShouldPay = value
    }
}

extension PayRelation: Equatable {
    static func == (lhs: PayRelation, rhs: PayRelation) -> Bool {
        return lhs.payerID == rhs.payerID && lhs.payeeID == rhs.payeeID
    }
}

extension PayRelation: CustomStringConvertible {
    var description: String {
        
        return "\(self.payeeID) should pay \(self.payerID) \(valueShouldPay) \n"
    }
}







