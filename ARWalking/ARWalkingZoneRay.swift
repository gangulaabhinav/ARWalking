//
//  ARWalkingZoneRay.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 18/07/22.
//

import RealityKit

class ARWalkingZoneRay {
    let sphereRadius: Float = 0.1
    var modelEntity: ModelEntity

    init(with parentModel: ModelEntity, material: Material, x: Float, y: Float) {
        let sphereMesh: MeshResource = .generateSphere(radius: sphereRadius)
        modelEntity = ModelEntity(mesh: sphereMesh, materials: [material])
        modelEntity.transform.translation = [x, y, 0.0]
        parentModel.addChild(modelEntity)
    }

    func update() {
        let distance = simd_length(modelEntity.position(relativeTo: modelEntity.parent!.parent))
        var material = SimpleMaterial()
        if distance > 2 {
            material.color =  .init(tint: .red.withAlphaComponent(0.5), texture: nil)
        } else {
            material.color =  .init(tint: .green.withAlphaComponent(0.5), texture: nil)
        }
        modelEntity.model?.materials = [material]
    }
}
