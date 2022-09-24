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
    @Published var isNavigating = false
    var sourceLocation = CGPoint()
    var destinationLocation = CGPoint()

    var navigationPath: [CGPoint] = []

    func startNavigation(from: CGPoint, to: CGPoint) {
        sourceLocation = from
        destinationLocation = to
        isNavigating = true
    }

    func setNavigationPath(navigationPath: [CGPoint]) {
        // Hack: This is being called everytime the view is updated. Returning if navigationPath is not empty
        if !self.navigationPath.isEmpty {
             return
        }
        self.navigationPath = navigationPath
        let routeString = "Route calculated. Estimated time 1 minute to destination. Start walking"
        // Note: This delay is required for the notificaiton ot be announced reliably. Else, other notifications are overtaking these announcements
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
          UIAccessibility.post(notification: .announcement, argument: routeString)
        }
    }

    func onLocationUpdated(x: CGFloat, y: CGFloat) {
        return
    }
}
