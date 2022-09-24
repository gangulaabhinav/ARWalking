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
    var currentLocationData: CurrentLocationData
    @ObservedObject var navigationManager: NavigationManager

    init() {
        let navManager = NavigationManager()
        self.navigationManager = navManager
        self.currentLocationData = CurrentLocationData(navigationManager: navManager)
    }

    @ViewBuilder
    private func getView() -> some View {
        VStack(spacing: 0) {
            BluetoothLEView(currentLocationData: currentLocationData)
            IndoorMapView(currentLocationData: currentLocationData, navigationManager: navigationManager)
                .frame(maxWidth: .infinity)
        }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
        if navigationManager.isNavigating {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity)
        } else {
            DestinationSelectionView(currentLocationData: currentLocationData, navigationManager: navigationManager)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity)
        }
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

class CurrentLocationData: ObservableObject {
    @Published var x: CGFloat = 25.0
    @Published var y: CGFloat = 23.0
    
    var navigationManager: NavigationManager

    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
    }
    
    func onLocationUpdated() {
        navigationManager.onLocationUpdated(x: x, y: y)
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
