//
//  visionARWalkingApp.swift
//  visionARWalking
//
//  Created by Abhinav Gangula on 09/09/23.
//

import SwiftUI

@main
struct visionARWalkingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }.immersionStyle(selection: .constant(.mixed), in: .mixed, .full, .progressive)
    }
}
