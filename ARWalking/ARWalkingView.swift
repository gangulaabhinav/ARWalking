//
//  ARWalkingView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 27/06/22.
//

import ARKit
import RealityKit
import SwiftUI

struct ARWalkingView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

final class ARViewContainer: NSObject, UIViewRepresentable, ARSessionDelegate {
    let arView: ARView = ARView(frame: .zero)
    var arWalkingZone: ARWalkingZone?

    override init() {
        super.init()
        arView.session.delegate = self
    }
    
    func makeUIView(context: Context) -> ARView {
        // configure plane detection
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        print("updateUIView!")
        return
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("frame updated")
        arWalkingZone?.onFrameUpdated(for: frame)
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("anchor added")
        updateFloorIfRequired(from: anchors, inSession: session)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("anchor updated")
        updateFloorIfRequired(from: anchors, inSession: session)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("anchor removed")
    }

    func updateFloorIfRequired(from anchors: [ARAnchor], inSession session: ARSession) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if planeAnchor.alignment == .horizontal {
                    switch planeAnchor.classification {
                    case .floor:
                        if arWalkingZone == nil {
                            arWalkingZone = ARWalkingZone(with: arView.scene, floorPlaneAnchor: planeAnchor)
                        }
                        arWalkingZone?.onFloorUpdated(with: planeAnchor)
                    default:
                        continue
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
		ARWalkingView()
    }
}
#endif
