//
//  ARWalkingZone.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 15/07/22.
//

import ARKit
import AVFoundation
import RealityKit

// Walking one with dimensions in meters
class ARWalkingZone {
    let width: Float = 0.6
    let height: Float = 2.0
    let depth: Float = 2.0
    let depthOffset: Float = 1.0 // Depth offset from camera to start measuring or raycasting, should be lass than the depth

//    var floorPlaneAnchor: ARPlaneAnchor
//    var floorModelEntity: ModelEntity
    var walkingZoneEntity: AnchorEntity
    var arWalkingZoneSurfaces = [ARWalkingZoneSurface.Direction: ARWalkingZoneSurface]()

//    var audioPlayer: AVAudioPlayer

//    init(with scene: Scene, floorPlaneAnchor: ARPlaneAnchor) {
    init() {
//        self.floorPlaneAnchor = floorPlaneAnchor
//        // Add floor ModelEntity to scene
//        var floorMaterial = SimpleMaterial()
//        floorMaterial.color =  .init(tint: .blue.withAlphaComponent(0.5), texture: nil)
//        floorModelEntity = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [floorMaterial])
//        let floorAnchorEntity = AnchorEntity()
//        floorAnchorEntity.addChild(floorModelEntity)
//        scene.anchors.append(floorAnchorEntity)

        var zoneMaterial = SimpleMaterial()
        zoneMaterial.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
        walkingZoneEntity = AnchorEntity()

        arWalkingZoneSurfaces[.front] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: width, height: height, rotationAxis: .y, rotationAngle: Float.pi/2)
        arWalkingZoneSurfaces[.right] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: depth - depthOffset, height: height)
        arWalkingZoneSurfaces[.left] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: depth - depthOffset, height: height, rotationAxis: .y, rotationAngle: Float.pi)
        arWalkingZoneSurfaces[.top] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: depth - depthOffset, height: width, rotationAxis: .x, rotationAngle: Float.pi/2)

//        scene.anchors.append(walkingZoneEntity)

//        let sound = Bundle.main.path(forResource: "sound", ofType: "mp3")
//        audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
        _ = session()
    }

//    func onFloorUpdated(with planeAnchor: ARPlaneAnchor) {
//        floorPlaneAnchor = planeAnchor
//        floorModelEntity.model?.mesh = .generatePlane(width: floorPlaneAnchor.extent.x, depth: floorPlaneAnchor.extent.z)
//        floorModelEntity.transform = Transform(matrix: floorPlaneAnchor.transform)
//        floorModelEntity.transform.translation += floorPlaneAnchor.center
//    }

//    func session(_ session: ARSession, didUpdate frame: ARFrame) -> ARWalkingZoneRay.RayCastResult {
    func session() -> ARWalkingZoneRay.RayCastResult {
//        let cameraTransform = frame.camera.transform
//        let walkingZoneTransform = getARWalkingZoneTransform(planeTransform: floorPlaneAnchor.transform, cameraTransform: cameraTransform)
//        walkingZoneEntity.transform = Transform(matrix: walkingZoneTransform)
//
//        let cameraFloorDstance = getCameraFloorDstance(floorTransform: floorPlaneAnchor.transform, cameraTransform: cameraTransform)
        let cameraFloorDstance = getCameraFloorDstance(floorTransform: simd_float4x4(), cameraTransform: simd_float4x4())
        var surfaceResults:[ARWalkingZoneRay.RayCastResult] = []
//        surfaceResults.append(arWalkingZoneSurfaces[.front]?.SetTranslation(translation: [-depth, height/2 - cameraFloorDstance, 0], with: session, frame: frame) ?? .green)
//        surfaceResults.append(arWalkingZoneSurfaces[.right]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height/2 - cameraFloorDstance, -width/2], with: session, frame: frame) ?? .green)
//        surfaceResults.append(arWalkingZoneSurfaces[.left]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height/2 - cameraFloorDstance, width/2], with: session, frame: frame) ?? .green)
//        surfaceResults.append(arWalkingZoneSurfaces[.top]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height - cameraFloorDstance, 0], with: session, frame: frame) ?? .green)
        surfaceResults.append(arWalkingZoneSurfaces[.front]?.SetTranslation(translation: [-depth, height/2 - cameraFloorDstance, 0]) ?? .green)
        surfaceResults.append(arWalkingZoneSurfaces[.right]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height/2 - cameraFloorDstance, -width/2]) ?? .green)
        surfaceResults.append(arWalkingZoneSurfaces[.left]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height/2 - cameraFloorDstance, width/2]) ?? .green)
        surfaceResults.append(arWalkingZoneSurfaces[.top]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height - cameraFloorDstance, 0]) ?? .green)

        var zoneResult:ARWalkingZoneRay.RayCastResult = .green
        for surfaceResult in surfaceResults {
            if surfaceResult == .red {
                zoneResult = surfaceResult
            } else if surfaceResult == .yellow && zoneResult == .green {
                zoneResult = surfaceResult
            }
        }
//        if zoneResult == .red {
//            audioPlayer.stop()
//        } else {
//            audioPlayer.play()
//        }
        return zoneResult
    }

    // Plane and Camera Anchor direction udnerstanding
    // Plane Anchor
    // Normal of plain points towards +Y direction. X and Z and along the plane
    // Camera Anchor
    // Camera points towards +Z direction. X & Y are in the plane of camera (almost in the plane of screen)

    // Returns transform with
    // Y pointing to the normal of floor (Y axis or floor)
    // -X pointing outwards of camera (x pointing inwards the camera)
    // Z pointing towards left of camera
    func getARWalkingZoneTransform(planeTransform: simd_float4x4, cameraTransform: simd_float4x4) -> simd_float4x4 {
        // setting outout transform to plane rotation but camera translation
        var arWalkingZoneTransform = Transform(matrix: planeTransform)
        arWalkingZoneTransform.translation = simd_make_float3(cameraTransform[3])

        // set the translation for both the transforms to [0, 0, 0, 1]. We just need to calculate rotations.
        var planeTransform = planeTransform
        planeTransform[3] = [0, 0, 0, 1]
        var cameraTransform = cameraTransform
        cameraTransform[3] = [0, 0, 0, 1]
        // transform z [0, 0, 1] point from camera transform to plane transform
        let a: simd_float4 = [0, 0, 1, 1]
        // b = a * Tainv * Tb
        let b = a * cameraTransform.inverse * planeTransform
        let x = b[0]
        let z = b[2]
        var theta: Float = 0.0
        if x == 0.0 {
            theta = z > 0 ? Float.pi/2 : 3*Float.pi/2
        } else {
            theta = atan(z/x)
            if x < 0.0 {
                theta += Float.pi
            }
        }
        // rotate aroung y axis with angle -theta
        arWalkingZoneTransform.rotation *= simd_quatf(angle: -theta, axis: SIMD3<Float>(0, 1, 0))
        return arWalkingZoneTransform.matrix
    }

    func getCameraFloorDstance(floorTransform: simd_float4x4, cameraTransform: simd_float4x4) -> Float {
//        let cameraPoint = cameraTransform[3]
//        // transform cameraPoin in local coordinates to floorTansoform coordinates and take the y coordinate as distance
//        let cameraPointwrtFloor = floorTransform.inverse * cameraPoint
//        return cameraPointwrtFloor[1]
        return 1.0
    }
}
