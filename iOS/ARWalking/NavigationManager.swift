//
//  NavigationManager.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import Foundation

class NavigationManager: ObservableObject {
    @Published var isNavigating = false
    
    func startNavigation() {
        isNavigating = true
    }
}
