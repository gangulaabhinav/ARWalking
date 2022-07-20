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
    }
}
