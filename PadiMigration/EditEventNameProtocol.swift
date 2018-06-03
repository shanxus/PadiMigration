//
//  EditEventNameProtocol.swift
//  FastQuantum
//
//  Created by Shan on 2018/3/18.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import Foundation

protocol PassEventNameBack {
    func passEventName(event name: String)
}

protocol PassSelectedMemberback {
    func passSelectedMember(member: [String])
}
