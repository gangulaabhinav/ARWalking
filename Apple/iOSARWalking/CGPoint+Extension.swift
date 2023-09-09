//
//  CGPoint_Extension.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import CoreGraphics

extension CGPoint {
    static func +(left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    func distance(x: CGFloat, y: CGFloat) -> CGFloat {
        let xDist = x - self.x
        let yDist = y - self.y
        return CGFloat(sqrt(xDist * xDist + yDist * yDist))
    }
    
    func getVector(from: CGPoint) -> CGVector { // get vector from the specified point to this point
        return CGVector(dx: self.x - from.y, dy: self.y - from.y)
    }

    func getVector(to: CGPoint) -> CGVector { // get vector from the this point to the specified point
        return CGVector(dx: to.y - self.x, dy: to.y - self.y)
    }
}
