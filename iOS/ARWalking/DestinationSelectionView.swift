//
//  DestinationSelectionView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import SwiftUI

struct DestinationSelectionView: View {
    var navigationManager: NavigationManager
    var currentLocationData: CurrentLocationData

    init(currentLocationData: CurrentLocationData, navigationManager: NavigationManager) {
        self.currentLocationData = currentLocationData
        self.navigationManager = navigationManager
    }

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            Text("Select a destination")
                .font(.largeTitle)
            Button("Sample Destination 1") {
                navigationManager.startNavigation(from: CGPoint(x: currentLocationData.x, y: currentLocationData.y), to: CGPoint(x: 10, y: 17.0))
            }
            Button("Sample Destination 2") {
                navigationManager.startNavigation(from: CGPoint(x: currentLocationData.x, y: currentLocationData.y), to: CGPoint(x: 15.5, y: 10.0))
            }
            Button("Sample Destination 3") {
                navigationManager.startNavigation(from: CGPoint(x: currentLocationData.x, y: currentLocationData.y), to: CGPoint(x: 22, y: 9.0))
            }
            Button("Sample Destination 4") {
                navigationManager.startNavigation(from: CGPoint(x: currentLocationData.x, y: currentLocationData.y), to: CGPoint(x: 33, y: 17.0))
            }
            Spacer()
        }
    }
}

struct DestinationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationSelectionView(currentLocationData: CurrentLocationData(navigationManager: NavigationManager()), navigationManager: NavigationManager())
    }
}
