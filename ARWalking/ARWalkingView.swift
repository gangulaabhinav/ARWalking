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
    var frontModelEntity: ModelEntity?
    var rightModelEntity: ModelEntity?
    var leftModelEntity: ModelEntity?
    var topModelEntity: ModelEntity?

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
        updateARWalkingZone(for: frame)
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
                        onFloorUpdated(with: planeAnchor, inSession: session)
                    default:
                        continue
                    }
                }
            }
        }
    }

    func onFloorUpdated(with planeAnchor: ARPlaneAnchor, inSession session: ARSession) {
        floorPlaneAnchor = planeAnchor
        if floorModelEntity == nil {
            // Draw floor
            var material = SimpleMaterial()
            material.color =  .init(tint: .blue.withAlphaComponent(0.5), texture: nil)
            floorModelEntity = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [material])
            let floorAnchorEntity = AnchorEntity()
            floorAnchorEntity.addChild(floorModelEntity!)
            arView.scene.anchors.append(floorAnchorEntity)

            drawWalkingZoneWith()
        }

        floorModelEntity!.model?.mesh = .generatePlane(width: floorPlaneAnchor!.extent.x, depth: floorPlaneAnchor!.extent.z)
        floorModelEntity!.transform = Transform(matrix: floorPlaneAnchor!.transform)
        floorModelEntity!.transform.translation += floorPlaneAnchor!.center
    }

    func drawWalkingZoneWith() {
        let arWalkingZone = ARWalkingZone()
        var material = SimpleMaterial()
        material.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
        walkingZoneEntity = AnchorEntity()

        // front zone
        let frontMesh: MeshResource = .generatePlane(width: arWalkingZone.width, height: arWalkingZone.height)
        frontModelEntity = ModelEntity(mesh: frontMesh, materials: [material])
        var frontTransform = Transform.identity
        frontTransform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 1, 0])
        frontModelEntity!.transform = frontTransform
        walkingZoneEntity!.addChild(frontModelEntity!)

        // right zone
        let rightMesh: MeshResource = .generatePlane(width: arWalkingZone.depth, height: arWalkingZone.height)
        rightModelEntity = ModelEntity(mesh: rightMesh, materials: [material])
        walkingZoneEntity!.addChild(rightModelEntity!)

        // left zone
        let leftMesh: MeshResource = rightMesh
        leftModelEntity = ModelEntity(mesh: leftMesh, materials: [material])
        var leftTransform = Transform.identity
        leftTransform.rotation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
        leftModelEntity!.transform = leftTransform
        walkingZoneEntity!.addChild(leftModelEntity!)

        // top zone
        let topMesh: MeshResource = .generatePlane(width: arWalkingZone.depth, depth: arWalkingZone.width)
        topModelEntity = ModelEntity(mesh: topMesh, materials: [material])
        var topTransform = Transform.identity
        topTransform.rotation = simd_quatf(angle: Float.pi, axis: [0, 0, 1])
        topModelEntity!.transform = topTransform
        walkingZoneEntity!.addChild(topModelEntity!)

        arView.scene.anchors.append(walkingZoneEntity!)
    }

    func updateARWalkingZone(for frame: ARFrame) {
        if walkingZoneEntity == nil {
            return
        }
        let cameraTransform = frame.camera.transform
        let walkingZoneTransform = GetARWalkingZoneTransform(planeTransform: floorPlaneAnchor!.transform, cameraTransform: cameraTransform)
        walkingZoneEntity!.transform = Transform(matrix: walkingZoneTransform)

        let arWalkingZone = ARWalkingZone()
        let cameraFloorDstance = GetCameraFloorDstance(floorTransform: floorPlaneAnchor!.transform, cameraTransform: cameraTransform)
        frontModelEntity!.transform.translation = [-arWalkingZone.depth, arWalkingZone.height/2 - cameraFloorDstance, 0]
        rightModelEntity!.transform.translation = [-arWalkingZone.depth/2, arWalkingZone.height/2 - cameraFloorDstance, -arWalkingZone.width/2]
        leftModelEntity!.transform.translation = [-arWalkingZone.depth/2, arWalkingZone.height/2 - cameraFloorDstance, arWalkingZone.width/2]
        topModelEntity!.transform.translation = [-arWalkingZone.depth/2, arWalkingZone.height - cameraFloorDstance, 0]
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
		ARWalkingView()
    }
}
#endif
