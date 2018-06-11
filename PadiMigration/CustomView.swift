//
//  CustomView.swift
//  FastQuantum
//
//  Created by Shan on 2018/4/26.
//  Copyright © 2018年 ShanStation. All rights reserved.
//

import UIKit

class CustomView: UIView {

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(gray: 0.3, alpha: 0.3)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 0, y: bounds.height))
            context.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            context.strokePath()
        }
    }
}

class CustomViewWithTwoSeperatorLine: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(gray: 0.3, alpha: 0.3)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 0, y: bounds.height))
            context.addLine(to: CGPoint(x: bounds.width, y: 0))
            context.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            context.strokePath()
        }
    }
}
