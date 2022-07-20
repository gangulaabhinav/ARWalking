//
//  ARWalkingZoneRay.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 18/07/22.
//

import RealityKit

class ARWalkingZoneRay {
    let sphereRadius: Float = 0.1
    let x: Float
    let y: Float

    init(with parentModel: ModelEntity, material: Material, x: Float, y: Float) {
        self.x = x
        self.y = y
        let sphereMesh: MeshResource = .generateSphere(radius: sphereRadius)
        let modelEntity = ModelEntity(mesh: sphereMesh, materials: [material])
        modelEntity.transform.translation = [x, y, 0.0]
        parentModel.addChild(modelEntity)

        var textMaterial = SimpleMaterial()
        textMaterial.color =  .init(tint: .red.withAlphaComponent(0.5), texture: nil)
        let pointInParentTransform = parentModel.transform.matrix * [x, y, 0.0, 1]
        let distance = simd_distance(pointInParentTransform, [0.0, 0.0, 0.0, 1])
        let textMesh: MeshResource = .generateText(String(distance), extrusionDepth: 0.01, font: .systemFont(ofSize: 0.1))
        let textModelEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        textModelEntity.transform.translation = [x, y, 0.0]
        parentModel.addChild(textModelEntity)
    }
}
