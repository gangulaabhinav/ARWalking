//
//  ImmersiveView.swift
//  visionARWalking
//
//  Created by Abhinav Gangula on 09/09/23.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    private let walkingZone = ARWalkingZone()

    var body: some View {
        RealityView { content in
            content.add(walkingZone.walkingZoneEntity)
        } update: { content in
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
