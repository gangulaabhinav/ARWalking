//
//  DestinationSelectionView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import SwiftUI

struct DestinationSelectionView: View {
    var navigationManager: NavigationManager

    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }

    var body: some View {
        VStack {
            Text("Select a destination")
                .font(.largeTitle)
            Button("Conference Room 006") {
                navigationManager.startNavigation()
            }
            Button("Conference Room 055") {}
            Button("Conference Room 143") {}
            Button("Conference Room 144") {}
        }
    }
}

struct DestinationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DestinationSelectionView(navigationManager: NavigationManager())
    }
}
