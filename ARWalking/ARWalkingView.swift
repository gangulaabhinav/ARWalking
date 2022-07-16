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
    var floorPlaneAnchor: ARPlaneAnchor?
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
        //guard let transform = session.currentFrame?.camera.transform
        //else { return }
        //if walkingZoneEntity == nil {
        //    return
        //}
        //walkingZoneEntity!.transform = Transform(matrix: transform)
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("anchor added")
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                if planeAnchor.alignment == .horizontal {
                    switch planeAnchor.classification {
                    case .floor:
                        onFloorDetected(with: planeAnchor, inSession: session)
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

    func onFloorDetected(with planeAnchor: ARPlaneAnchor, inSession session: ARSession) {
        floorPlaneAnchor = planeAnchor
        arView.scene.anchors.removeAll() // reset all anchor enitities on new plane detection

        // Draw floor
        let planeMesh: MeshResource = .generatePlane(width: floorPlaneAnchor!.extent.x, depth: floorPlaneAnchor!.extent.z)
        var material = SimpleMaterial()
        material.color =  .init(tint: .blue.withAlphaComponent(0.5), texture: nil)
        floorModelEntity = ModelEntity(mesh: planeMesh, materials: [material])
        let floorAnchorEntity = AnchorEntity(anchor: planeAnchor)
        floorAnchorEntity.addChild(floorModelEntity!)
        arView.scene.anchors.append(floorAnchorEntity)

        // Draw ARWalkingZone
        guard let cameraTransform = session.currentFrame?.camera.transform
        else { return }
        let walkingZoneTransform = GetARWalkingZoneTransform(planeTransform: floorPlaneAnchor!.transform, cameraTransform: cameraTransform)
        let cameraFloorDstance = GetCameraFloorDstance(floorTransform: floorPlaneAnchor!.transform, cameraTransform: cameraTransform)
        let cameraAnchor = ARAnchor(transform: walkingZoneTransform)
        session.add(anchor: cameraAnchor)
        drawWalkingZoneWith(cameraAnchor: cameraAnchor, cameraFloorDstance: cameraFloorDstance)
    }

    func drawWalkingZoneWith(cameraAnchor: ARAnchor, cameraFloorDstance: Float) {
        let arWalkingZone = ARWalkingZone()
        var material = SimpleMaterial()
        material.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
        walkingZoneEntity = AnchorEntity(anchor: cameraAnchor)

        // front zone
        let frontMesh: MeshResource = .generatePlane(width: arWalkingZone.width, height: arWalkingZone.height)
        let frontModelEntity = ModelEntity(mesh: frontMesh, materials: [material])
        var frontTransform = Transform.identity
        frontTransform.translation = [-arWalkingZone.depth, arWalkingZone.height/2 - cameraFloorDstance, 0]
        frontTransform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 1, 0])
        frontModelEntity.transform = frontTransform
        walkingZoneEntity!.addChild(frontModelEntity)

        // right zone
        let rightMesh: MeshResource = .generatePlane(width: arWalkingZone.depth, height: arWalkingZone.height)
        let rightModelEntity = ModelEntity(mesh: rightMesh, materials: [material])
        var rightTransform = Transform.identity
        rightTransform.translation = [-arWalkingZone.depth/2, arWalkingZone.height/2 - cameraFloorDstance, -arWalkingZone.width/2]
        rightModelEntity.transform = rightTransform
        walkingZoneEntity!.addChild(rightModelEntity)

        // left zone
        let leftMesh: MeshResource = rightMesh
        let leftModelEntity = ModelEntity(mesh: leftMesh, materials: [material])
        var leftTransform = Transform.identity
        leftTransform.translation = [-arWalkingZone.depth/2, arWalkingZone.height/2 - cameraFloorDstance, arWalkingZone.width/2]
        leftTransform.rotation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
        leftModelEntity.transform = leftTransform
        walkingZoneEntity!.addChild(leftModelEntity)

        // top zone
        let topMesh: MeshResource = .generatePlane(width: arWalkingZone.depth, depth: arWalkingZone.width)
        let topModelEntity = ModelEntity(mesh: topMesh, materials: [material])
        var topTransform = Transform.identity
        topTransform.translation = [-arWalkingZone.depth/2, arWalkingZone.height - cameraFloorDstance, 0]
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
