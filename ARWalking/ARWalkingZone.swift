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
    let rayThickness: Float = 0.01

    var floorPlaneAnchor: ARPlaneAnchor
    var floorModelEntity: ModelEntity
    var walkingZoneEntity: AnchorEntity
    var frontModelEntity: ModelEntity
    var rightModelEntity: ModelEntity
    var leftModelEntity: ModelEntity
    var topModelEntity: ModelEntity
    var textModelEntity: ModelEntity

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

        // front zone
        let frontMesh: MeshResource = .generatePlane(width: width, height: height)
        frontModelEntity = ModelEntity(mesh: frontMesh, materials: [zoneMaterial])
        var frontTransform = Transform.identity
        frontTransform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 1, 0])
        frontModelEntity.transform = frontTransform
        walkingZoneEntity.addChild(frontModelEntity)

        // right zone
        let rightMesh: MeshResource = .generatePlane(width: depth, height: height)
        rightModelEntity = ModelEntity(mesh: rightMesh, materials: [zoneMaterial])
        walkingZoneEntity.addChild(rightModelEntity)

        // left zone
        let leftMesh: MeshResource = rightMesh
        leftModelEntity = ModelEntity(mesh: leftMesh, materials: [zoneMaterial])
        var leftTransform = Transform.identity
        leftTransform.rotation = simd_quatf(angle: Float.pi, axis: [0, 1, 0])
        leftModelEntity.transform = leftTransform
        walkingZoneEntity.addChild(leftModelEntity)

        // top zone
        let topMesh: MeshResource = .generatePlane(width: depth, height: width)
        topModelEntity = ModelEntity(mesh: topMesh, materials: [zoneMaterial])
        var topTransform = Transform.identity
        topTransform.rotation = simd_quatf(angle: Float.pi/2, axis: [1, 0, 0])
        topModelEntity.transform = topTransform
        walkingZoneEntity.addChild(topModelEntity)

        // Drawing a ray in the outward direction of camera and adding a placeholder text for displaying camera raycast distance
        let rayMesh: MeshResource = .generateBox(width: depth, height: rayThickness, depth: rayThickness)
        let rayModelEntity = ModelEntity(mesh: rayMesh, materials: [zoneMaterial])
        walkingZoneEntity.addChild(rayModelEntity)
        var textMaterial = SimpleMaterial()
        textMaterial.color =  .init(tint: .red.withAlphaComponent(0.5), texture: nil)
        let textMesh: MeshResource = .generateText("0.0", extrusionDepth: 0.1, font: .systemFont(ofSize: 0.1))
        textModelEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textModelEntity.transform.translation = [-depth/2 , 0, 0]
        textModelEntity.transform.rotation = simd_quatf(angle: Float.pi/2, axis: [0, 1, 0])
        walkingZoneEntity.addChild(textModelEntity)

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
        frontModelEntity.transform.translation = [-depth, height/2 - cameraFloorDstance, 0]
        rightModelEntity.transform.translation = [-depth/2, height/2 - cameraFloorDstance, -width/2]
        leftModelEntity.transform.translation = [-depth/2, height/2 - cameraFloorDstance, width/2]
        topModelEntity.transform.translation = [-depth/2, height - cameraFloorDstance, 0]

        // Tryign to raycast from camera in the -Z direction of the camera (outwards of the camera) and displaying the distance
        // The direction of z axis may not be perfect. But, works for now as this is temp code.
        let rayCastQuery = ARRaycastQuery(origin: simd_make_float3(frame.camera.transform.columns.3), direction: -simd_make_float3(frame.camera.transform.columns.2), allowing: .estimatedPlane, alignment: .any)
        let rayCastResult = session.raycast(rayCastQuery)
        if !rayCastResult.isEmpty {
            let worldPos = simd_make_float3(rayCastResult[0].worldTransform.columns.3)
            let cameraPos = simd_make_float3(frame.camera.transform.columns.3)
            let distane = simd_distance(cameraPos, worldPos)
            textModelEntity.model?.mesh = .generateText(String(distane), extrusionDepth: 0.1, font: .systemFont(ofSize: 0.1))
        }
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
