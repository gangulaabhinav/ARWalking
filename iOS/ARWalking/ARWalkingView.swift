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
    @ViewBuilder
    private func getView() -> some View {
        VStack(spacing: 0) {
            BluetoothLEView()
            IndoorMapView()
                .frame(maxWidth: .infinity)
        }
            .frame(maxWidth: .infinity)
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity)
    }
    
    var body: some View {
        GeometryReader { ruler in
            if ruler.size.width < ruler.size.height { // Portrait
                VStack(spacing: 0) {
                    getView()
                }
            } else { // landscape
                HStack(spacing: 0) {
                    getView()
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var arWalkingSessionDelegate = ARWalkingSessionDelegate()
    
    func makeUIView(context: Context) -> ARView {
        return arWalkingSessionDelegate.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        return
    }
}

final class ARWalkingSessionDelegate: NSObject, ARSessionDelegate {
    let arView: ARView = ARView(frame: .zero)
    var arWalkingZone: ARWalkingZone?

    override init() {
        super.init()
        // configure plane detection
        arView.automaticallyConfigureSession = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
        arView.session.delegate = self
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        _ = arWalkingZone?.session(session, didUpdate: frame)
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        updateFloorIfRequired(inSession: session, from: anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        updateFloorIfRequired(inSession: session, from: anchors)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    }

    func updateFloorIfRequired(inSession session: ARSession, from anchors: [ARAnchor]) {
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
