//
//  ImmersiveView.swift
//  visionARWalking
//
//  Created by Abhinav Gangula on 09/09/23.
//

import ARKit
import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    let session = ARKitSession()
    let worldTrackingProvider = WorldTrackingProvider()
    private let walkingZone = ARWalkingZone()

    var body: some View {
        RealityView { content in
            content.add(walkingZone.walkingZoneEntity)
        } update: { content in
        }
        .task {
            await startSession()
        }
        .onDisappear {
            stopSession()
        }
    }

    func startSession() async {
        print("WorldTrackingProvider.isSupported: \(WorldTrackingProvider.isSupported)")
        print("PlaneDetectionProvider.isSupported: \(PlaneDetectionProvider.isSupported)")
        print("SceneReconstructionProvider.isSupported: \(SceneReconstructionProvider.isSupported)")
        print("HandTrackingProvider.isSupported: \(HandTrackingProvider.isSupported)")

        Task {
            let authorizationResult = await session.requestAuthorization(for: [.worldSensing])

            for (authorizationType, authorizationStatus) in authorizationResult {
                print("Authorization status for \(authorizationType): \(authorizationStatus)")
                switch authorizationStatus {
                case .allowed:
                    break
                case .denied:
                    // Need to handle this.
                    break
                case .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
        }

        Task {
            let floorAnchor = await AnchorEntity(.plane(.horizontal, classification: .floor,
                                                             minimumBounds: [1, 1]))
            walkingZone.onFloorUpdated(with: floorAnchor)
            if WorldTrackingProvider.isSupported {
                do {
                    try await session.run([worldTrackingProvider])
                    guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else {
                        return
                    }
                    _ = walkingZone.session(cameraTransform: deviceAnchor.originFromAnchorTransform)
                } catch {
                    assertionFailure("Failed to run session: \(error)")
                }
            }
        }
    }

    func stopSession() {
        session.stop()
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
