//
//  ARWalkingZone.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 15/07/22.
//

import ARKit
import RealityKit

// Walking one with dimensions in meters
class ARWalkingZone {
    let width: Float = 1.0
    let height: Float = 2.0
    let depth: Float = 4.0
    let depthOffset: Float = 0.5 // Depth offset from camera to start measuring or raycasting, should be lass than the depth
    let rayThickness: Float = 0.01

    var floorPlaneAnchor: ARPlaneAnchor
    var floorModelEntity: ModelEntity
    var walkingZoneEntity: AnchorEntity
    var arWalkingZoneSurfaces = [ARWalkingZoneSurface.Direction: ARWalkingZoneSurface]()

    init(with scene: Scene, floorPlaneAnchor: ARPlaneAnchor) {
        self.floorPlaneAnchor = floorPlaneAnchor
        // Add floor ModelEntity to scene
        var floorMaterial = SimpleMaterial()
        floorMaterial.color =  .init(tint: .blue.withAlphaComponent(0.5), texture: nil)
        floorModelEntity = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [floorMaterial])
        let floorAnchorEntity = AnchorEntity()
        floorAnchorEntity.addChild(floorModelEntity)
        scene.anchors.append(floorAnchorEntity)

        var zoneMaterial = SimpleMaterial()
        zoneMaterial.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
        walkingZoneEntity = AnchorEntity()

        arWalkingZoneSurfaces[.front] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: width, height: height, rotationAxis: .y, rotationAngle: Float.pi/2)
        arWalkingZoneSurfaces[.right] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: depth - depthOffset, height: height)
        arWalkingZoneSurfaces[.left] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: depth - depthOffset, height: height, rotationAxis: .y, rotationAngle: Float.pi)
        arWalkingZoneSurfaces[.top] = ARWalkingZoneSurface(with: walkingZoneEntity, material: zoneMaterial, width: depth - depthOffset, height: width, rotationAxis: .x, rotationAngle: Float.pi/2)

        scene.anchors.append(walkingZoneEntity)
    }

    func onFloorUpdated(with planeAnchor: ARPlaneAnchor) {
        floorPlaneAnchor = planeAnchor
        floorModelEntity.model?.mesh = .generatePlane(width: floorPlaneAnchor.extent.x, depth: floorPlaneAnchor.extent.z)
        floorModelEntity.transform = Transform(matrix: floorPlaneAnchor.transform)
        floorModelEntity.transform.translation += floorPlaneAnchor.center
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let cameraTransform = frame.camera.transform
        let walkingZoneTransform = getARWalkingZoneTransform(planeTransform: floorPlaneAnchor.transform, cameraTransform: cameraTransform)
        walkingZoneEntity.transform = Transform(matrix: walkingZoneTransform)

        let cameraFloorDstance = getCameraFloorDstance(floorTransform: floorPlaneAnchor.transform, cameraTransform: cameraTransform)
        arWalkingZoneSurfaces[.front]?.SetTranslation(translation: [-depth, height/2 - cameraFloorDstance, 0], with: session, frame: frame)
        arWalkingZoneSurfaces[.right]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height/2 - cameraFloorDstance, -width/2], with: session, frame: frame)
        arWalkingZoneSurfaces[.left]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height/2 - cameraFloorDstance, width/2], with: session, frame: frame)
        arWalkingZoneSurfaces[.top]?.SetTranslation(translation: [-depth/2 - depthOffset/2, height - cameraFloorDstance, 0], with: session, frame: frame)
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
        var newTransform = Transform(matrix: planeTransform)
        // rotate aroung y axis with angle -theta
        newTransform.rotation *= simd_quatf(angle: -theta, axis: SIMD3<Float>(0, 1, 0))
        return newTransform.matrix
    }

    func getCameraFloorDstance(floorTransform: simd_float4x4, cameraTransform: simd_float4x4) -> Float {
        let cameraPoint = cameraTransform[3]
        // transform cameraPoin in local coordinates to floorTansoform coordinates and take the y coordinate as distance
        let cameraPointwrtFloor = floorTransform.inverse * cameraPoint
        return cameraPointwrtFloor[1]
    }
}
