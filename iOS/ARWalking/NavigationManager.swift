//
//  NavigationManager.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import Foundation
import CoreGraphics

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
        self.navigationPath = navigationPath
    }

    func onLocationUpdated(x: CGFloat, y: CGFloat) {
        return
    }
}
