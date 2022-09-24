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
        VStack {
            Text("Select a destination")
                .font(.largeTitle)
            Button("Conference Room 006") {
                navigationManager.startNavigation(from: CGPoint(x: currentLocationData.x, y: currentLocationData.y), to: CGPoint(x: -4.0, y: 0.0))
            }
            Button("Conference Room 055") {}
            Button("Conference Room 143") {}
            Button("Conference Room 144") {}
        }
    }
}

struct DestinationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationSelectionView(currentLocationData: CurrentLocationData(navigationManager: NavigationManager()), navigationManager: NavigationManager())
    }
}
