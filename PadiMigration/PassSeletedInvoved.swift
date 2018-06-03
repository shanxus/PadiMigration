//
//  PassSeletedInvoved.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/28.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation

protocol PassSelectedInvoledPayee {
    func passSelectedInvolvedIDBack(IDs: [String])
}

protocol PassSelectedInvolvedPayer {
    func passSelectedInvolvedPayerBack(info: [String:Float])
}

protocol PassSelectedPersonalPay {
    func passSelectedPersonalPay(pairs: [PersonalPayInfo])
}
