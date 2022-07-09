//
//  ARWalkingView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 27/06/22.
//

import ARKit
import RealityKit
import SwiftUI

// Walking one with dimensions in meters
struct ARWalkingZone {
    let width: Float = 1.0
    let height: Float = 2.0
    let depth: Float = 4.0
}

struct ARWalkingView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

final class ARViewContainer: NSObject, UIViewRepresentable, ARSessionDelegate {
    let arView: ARView = ARView(frame: .zero)
    var floorModelEntity: ModelEntity?
    var walkingZoneEntity: AnchorEntity?

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
        guard let transform = session.currentFrame?.camera.transform
        else { return }
        if walkingZoneEntity == nil {
            return
        }
        walkingZoneEntity!.transform = Transform(matrix: transform)
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("anchor added")
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if planeAnchor.alignment == .horizontal {
                    switch planeAnchor.classification {
                    case .floor:
                        drawFloorWith(planeAnchor: planeAnchor)
                        guard let transform = session.currentFrame?.camera.transform
                        else { return }
                        let cameraAnchor = ARAnchor(transform: transform)
                        session.add(anchor: cameraAnchor)
                        drawWalkingZoneWith(cameraAnchor: cameraAnchor)
                    default:
                        continue
                    }
                }
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("anchor updated")
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if planeAnchor.alignment == .horizontal {
                    switch planeAnchor.classification {
                    case .floor:
                        if floorModelEntity == nil {
                            continue
                        }
                        let planeMesh: MeshResource = .generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z)
                        floorModelEntity!.model?.mesh = planeMesh
                        var transform = Transform.identity
                        transform.translation = planeAnchor.center
                        floorModelEntity!.transform = transform
                    default:
                        continue
                    }
                }
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("anchor removed")
    }
    
    func drawFloorWith(planeAnchor: ARPlaneAnchor) {
        let planeMesh: MeshResource = .generatePlane(width: planeAnchor.extent.x, depth: planeAnchor.extent.z)
        var material = SimpleMaterial()
        material.color =  .init(tint: .blue.withAlphaComponent(0.5), texture: nil)
        floorModelEntity = ModelEntity(mesh: planeMesh, materials: [material])
        let floorAnchorEntity = AnchorEntity(anchor: planeAnchor)
        floorAnchorEntity.addChild(floorModelEntity!)
        arView.scene.anchors.append(floorAnchorEntity)
    }
    
    func drawWalkingZoneWith(cameraAnchor: ARAnchor) {
        let arWalkingZone = ARWalkingZone()
        var material = SimpleMaterial()
        material.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
        walkingZoneEntity = AnchorEntity(anchor: cameraAnchor)

        // front zone
        let frontMesh: MeshResource = .generatePlane(width: arWalkingZone.width, height: arWalkingZone.height)
        let frontModelEntity = ModelEntity(mesh: frontMesh, materials: [material])
        var frontTransform = Transform.identity
        frontTransform.translation = [0, arWalkingZone.height/2, -arWalkingZone.depth/2]
        frontModelEntity.transform = frontTransform
        walkingZoneEntity!.addChild(frontModelEntity)

        // left zone
        let leftMesh: MeshResource = .generatePlane(width: arWalkingZone.height, depth: arWalkingZone.depth)
        let leftModelEntity = ModelEntity(mesh: leftMesh, materials: [material])
        var leftTransform = Transform.identity
        leftTransform.translation = [-arWalkingZone.width/2, arWalkingZone.height/2, 0]
        leftTransform.rotation = simd_quatf(angle: -Float.pi/2, axis: [0, 0, 1])
        leftModelEntity.transform = leftTransform
        walkingZoneEntity!.addChild(leftModelEntity)

        // right zone
        let rightMesh: MeshResource = leftMesh
        let rightModelEntity = ModelEntity(mesh: rightMesh, materials: [material])
        var rightTransform = Transform.identity
        rightTransform.translation = [arWalkingZone.width/2, arWalkingZone.height/2, 0]
        rightTransform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 0, 1])
        rightModelEntity.transform = rightTransform
        walkingZoneEntity!.addChild(rightModelEntity)

        // top zone
        let topMesh: MeshResource = .generatePlane(width: arWalkingZone.width, depth: arWalkingZone.depth)
        let topModelEntity = ModelEntity(mesh: topMesh, materials: [material])
        var topTransform = Transform.identity
        topTransform.translation = [0, arWalkingZone.height, 0]
        topTransform.rotation = simd_quatf(angle: Float.pi, axis: [0, 0, 1])
        topModelEntity.transform = topTransform
        walkingZoneEntity!.addChild(topModelEntity)

        arView.scene.anchors.append(walkingZoneEntity!)
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
		ARWalkingView()
    }
}
#endif
