//
//  EditEventNameProtocol.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/18.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation

protocol PassEventNameBack: AnyObject {
    func passEventName(event name: String)
}

protocol PassSelectedMemberback: AnyObject {
    func passSelectedMember(member: [String])
}
