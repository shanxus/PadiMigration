//
//  PassSeletedInvoved.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/28.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation

protocol PassSelectedInvoledPayee: AnyObject {
    func passSelectedInvolvedIDBack(IDs: [String])
}

protocol PassSelectedInvolvedPayer: AnyObject {
    func passSelectedInvolvedPayerBack(info: [String:Float])
}

protocol PassSelectedPersonalPay: AnyObject {
    func passSelectedPersonalPay(pairs: [PersonalPayInfo])
}
