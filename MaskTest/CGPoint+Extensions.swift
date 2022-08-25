//
//  CGPoint+Extensions.swift
//  draw_in_layer_context_test
//
//  Created by Pierre Hanna on 2022-08-17.
//

import Foundation
import UIKit

extension CGPoint {
    
    static func * (_ lhs: CGFloat, _ rhs: CGPoint) -> CGPoint {
        
        let x = lhs * rhs.x
        let y = lhs * rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func + (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func - (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        
        let x = lhs.x - rhs.x
        let y = lhs.y - rhs.y
        return CGPoint(x: x, y: y)
    }
    
    static func length(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        
        let v: CGPoint = lhs - rhs
        
        let magnitude = sqrt(v.x * v.x + v.y * v.y)
        return abs(magnitude)
    }
    
    static func length(_ p: CGPoint) -> CGFloat {

        let magnitude = sqrt(p.x * p.x + p.y * p.y)
        return abs(magnitude)
    }
    
    public var length: CGFloat {

        let magnitude: CGFloat = sqrt(self.x * self.x + self.y * self.y)
        return abs(magnitude)
    }
}
