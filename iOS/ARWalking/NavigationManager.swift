//
//  NavigationManager.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import Foundation
import CoreGraphics
import UIKit

class NavigationManager: ObservableObject {
    @Published var proximityForTurn = 1.0 // meters
    @Published var isNavigating = false

    var sourceLocation = CGPoint()
    var destinationLocation = CGPoint()

    var navigationPath: [CGPoint] = []
    var completedPoints: [Bool] = []

    func startNavigation(from: CGPoint, to: CGPoint) {
        sourceLocation = from
        destinationLocation = to
        isNavigating = true
    }

    func setNavigationPath(navigationPath: [CGPoint]) {
        // Hack: This is being called everytime the view is updated. Returning if navigationPath is not empty
        if !self.navigationPath.isEmpty || navigationPath.count < 1 {
             return
        }
        self.navigationPath = navigationPath
        let routeString = "Route calculated. Estimated time 1 minute to destination. Start walking"
        // Note: This delay is required for the notificaiton ot be announced reliably. Else, other notifications are overtaking these announcements
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
          UIAccessibility.post(notification: .announcement, argument: routeString)
        }
        
        // Mark the source as completed destinations
        completedPoints.removeAll()
        for _ in navigationPath {
            completedPoints.append(false)
        }
        completedPoints[0] = true
    }

    func onLocationUpdated(x: CGFloat, y: CGFloat) {
        var proximityPointIndex = -1
        if isNavigating {
            for (index, point) in navigationPath.enumerated() {
                let distance = point.distance(x: x, y: y)
                if (distance < proximityForTurn) && completedPoints[index] == false {
                    proximityPointIndex = index
                    completedPoints[index] = true
                }
            }
            // If we are near a turn that hasn't been visited previously, announce it
            if proximityPointIndex != -1 {
                var turnAnnouncement = "Turn now"
                if proximityPointIndex == navigationPath.count - 1 {
                    turnAnnouncement = "Reached destination"
                } else {
                    let arrivalVector = navigationPath[proximityPointIndex].getVector(from: navigationPath[proximityPointIndex - 1])
                    let destinationVector = navigationPath[proximityPointIndex].getVector(to: navigationPath[proximityPointIndex + 1])
                    let crossProduct = (arrivalVector.dx * destinationVector.dy) - (arrivalVector.dy * destinationVector.dx)
                    if crossProduct < 0 { // If the cross product is -ve, anti-clockwise, means left turn
                        turnAnnouncement = "Turn left"
                    } else {
                        turnAnnouncement = "Turn right"
                    }
                }
                UIAccessibility.post(notification: .announcement, argument: turnAnnouncement)
            }
        }
        return
    }
}
