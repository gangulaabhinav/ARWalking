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
        print("frame updates")
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("anchor added")
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if planeAnchor.alignment == .horizontal {
                    switch planeAnchor.classification {
                    case .floor:
                        let boxMesh: MeshResource = .generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z)
                        var material = SimpleMaterial()
                        material.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
                        let modelEntity = ModelEntity(mesh: boxMesh, materials: [material])
                        let planeAnchorEntity = AnchorEntity(anchor: planeAnchor)
                        planeAnchorEntity.addChild(modelEntity)
                        arView.scene.anchors.append(planeAnchorEntity)
                    default:
                        continue
                    }
                }
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("anchor updated")
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("anchor removed")
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
		ARWalkingView()
    }
}
#endif
