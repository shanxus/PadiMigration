//
//  PassSelectedImage.swift
//  PadiMigration
//
//  Created by Shan on 2018/7/4.
//  Copyright © 2018年 Shan. All rights reserved.
//

import Foundation

protocol PassSelectedImage: AnyObject {
    func pass(withImageData data: Data) 
}
