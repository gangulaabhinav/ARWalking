//
//  ARWalkingZoneRay.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 18/07/22.
//

import ARKit
import RealityKit

class ARWalkingZoneRay {
    enum RayCastResult
    {
        case green // ray cast if further from the model position, hence safe
        case yellow // in buffer zone
        case red // ray cast is near, so, no safe
    }

    let sphereRadius: Float = 0.1 // sphere radius to show spheres at raycast positions
    let rayCastBuffer: Float = 0.2 // The buffer zone in which ray-cast is assumed to be successful if if it is out of bounds
    var modelEntity: ModelEntity

    init(with parentModel: ModelEntity, material: Material, x: Float, y: Float) {
        let sphereMesh: MeshResource = .generateSphere(radius: sphereRadius)
        modelEntity = ModelEntity(mesh: sphereMesh, materials: [material])
        modelEntity.transform.translation = [x, y, 0.0]
        parentModel.addChild(modelEntity)
    }

    func update(with session: ARSession, frame: ARFrame) -> RayCastResult {
        let cameraPosition = simd_make_float3(frame.camera.transform.columns.3)
        let modelPositionInWorld = modelEntity.position(relativeTo: nil)
        let modelDistanceFromCamera = simd_distance(cameraPosition, modelPositionInWorld)
        // Tryign to raycast from camera to the model position

        let rayCastQuery = ARRaycastQuery(origin: cameraPosition, direction: modelPositionInWorld - cameraPosition, allowing: .estimatedPlane, alignment: .any)
        let rayCastResult = session.raycast(rayCastQuery)
        var rayCastDistance: Float = Float.greatestFiniteMagnitude // Assuming distance is maximum if there are no ray cast results
        if !rayCastResult.isEmpty {
            let worldPos = simd_make_float3(rayCastResult[0].worldTransform.columns.3)
            let cameraPos = simd_make_float3(frame.camera.transform.columns.3)
            rayCastDistance = simd_distance(cameraPos, worldPos)
        }
        let rayCastModelDistance = modelDistanceFromCamera - rayCastDistance

        var material = SimpleMaterial()
        var result:RayCastResult = .green
        if rayCastModelDistance > rayCastBuffer { // ray cast is closer to modelDistanceFromCamera, red color
            material.color =  .init(tint: .red.withAlphaComponent(1.0), texture: nil)
            result = .red
        } else if rayCastModelDistance > -rayCastBuffer { // buffer zone yellow color
            material.color =  .init(tint: .yellow.withAlphaComponent(1.0), texture: nil)
            result = .yellow
        } else {
            material.color =  .init(tint: .green.withAlphaComponent(1.0), texture: nil)
            result = .green
        }
        modelEntity.model?.materials = [material]
        return result
    }
}
