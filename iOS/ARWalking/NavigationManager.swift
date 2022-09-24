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
    static let ProximityForTurn = 1.0 // meters

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
                if (distance < NavigationManager.ProximityForTurn) && completedPoints[index] == false {
                    proximityPointIndex = index
                    completedPoints[index] = true
                }
            }
            // Hack: Harcoding it for now, ned to calculate based on previous point and next point
            // If we are near a turn that hasn't been visited previously, announce it
            if proximityPointIndex != -1 {
                var turnAnnouncement = "Turn now"
                if proximityPointIndex == 1 {
                    turnAnnouncement = "Turn left"
                } else if proximityPointIndex == 2 {
                    turnAnnouncement = "Turn right"
                } else if proximityPointIndex == navigationPath.count - 1 { // last point == destination
                    turnAnnouncement = "Reached destination"
                }
                UIAccessibility.post(notification: .announcement, argument: turnAnnouncement)
            }
        }
        return
    }
}
