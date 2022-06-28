//
//  ContentView.swift
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

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // configure horizontal lane detection
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)

        // add plane mesh model anchor to arView
        let boxMesh: MeshResource = .generatePlane(width: 0.5, depth: 0.5)
        let modelEntity = ModelEntity(mesh: boxMesh)
        let planeAnchor = AnchorEntity(.plane([.any],
                              classification: [.any],
                               minimumBounds: [0.5, 0.5]))
        planeAnchor.addChild(modelEntity)
        arView.scene.anchors.append(planeAnchor)

        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func startHorizontalPlaneDetectionInView(arView: ARView) {
        
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
		ARWalkingView()
    }
}
#endif
