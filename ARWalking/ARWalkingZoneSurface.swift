//
//  ARWalkingZoneSurface.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 18/07/22.
//

import RealityKit

class ARWalkingZoneSurface {
    enum RotationAxis
    {
        case x
        case y
        case z
    }

    var modelEntity: ModelEntity
    var rays: [ARWalkingZoneRay] = []

    init(with anchor: AnchorEntity, material: Material, width: Float, height: Float, rotationAxis: RotationAxis, rotationAngle: Float, rayDistance: Float) {
        let frontMesh: MeshResource = .generatePlane(width: width, height: height)
        modelEntity = ModelEntity(mesh: frontMesh, materials: [material])
        var frontTransform = Transform.identity
        frontTransform.rotation = GetquatfFromRotation(rotationAxis: rotationAxis, rotationAngle: rotationAngle)
        modelEntity.transform = frontTransform
        anchor.addChild(modelEntity)
    }

    func SetTranslation(translation: SIMD3<Float>) {
        modelEntity.transform.translation = translation
    }

    func GetquatfFromRotation(rotationAxis: RotationAxis, rotationAngle: Float) -> simd_quatf {
        switch rotationAxis {
        case .x:
            return simd_quatf(angle: rotationAngle, axis: [1, 0, 0])
        case .y:
            return simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        case .z:
            return simd_quatf(angle: rotationAngle, axis: [0, 0, 1])
        }
    }
}
