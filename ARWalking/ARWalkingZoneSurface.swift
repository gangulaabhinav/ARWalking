//
//  ARWalkingZoneSurface.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 18/07/22.
//

import ARKit
import RealityKit

class ARWalkingZoneSurface {
    enum Direction
    {
        case front
        case right
        case left
        case top
    }

    enum RotationAxis
    {
        case x
        case y
        case z
        case none
    }

    var modelEntity: ModelEntity
    var rays: [ARWalkingZoneRay] = []

    init(with anchor: AnchorEntity, material: Material, width: Float, height: Float, rotationAxis: RotationAxis = .none, rotationAngle: Float = 0.0, rayDistance: Float = 1.0) {
        let frontMesh: MeshResource = .generatePlane(width: width, height: height)
        modelEntity = ModelEntity(mesh: frontMesh, materials: [material])
        var frontTransform = Transform.identity
        frontTransform.rotation = GetquatfFromRotation(rotationAxis: rotationAxis, rotationAngle: rotationAngle)
        modelEntity.transform = frontTransform
        anchor.addChild(modelEntity)
        addRays(material: material, width: width, height: height)
    }

    func SetTranslation(translation: SIMD3<Float>, with session: ARSession, frame: ARFrame) {
        modelEntity.transform.translation = translation
        for ray in rays {
            ray.update(with: session, frame: frame)
        }
    }

    func addRays(material: Material, width: Float, height: Float) {
        rays.append(ARWalkingZoneRay(with: modelEntity, material: material, x: width/2, y: height/2))
        rays.append(ARWalkingZoneRay(with: modelEntity, material: material, x: width/2, y: -height/2))
        rays.append(ARWalkingZoneRay(with: modelEntity, material: material, x: -width/2, y: height/2))
        rays.append(ARWalkingZoneRay(with: modelEntity, material: material, x: -width/2, y: -height/2))
    }

    func GetquatfFromRotation(rotationAxis: RotationAxis, rotationAngle: Float) -> simd_quatf {
        switch rotationAxis {
        case .x:
            return simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
        case .y:
            return simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        case .z:
            return simd_quatf(angle: rotationAngle, axis: [0, 0, 1])
        case .none:
            return simd_quatf(angle: rotationAngle, axis: [0, 0, 0])
        }
    }
}
