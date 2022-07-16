//
//  ARWalkingZone.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 15/07/22.
//

import RealityKit

// Walking one with dimensions in meters
struct ARWalkingZone {
    let width: Float = 1.0
    let height: Float = 2.0
    let depth: Float = 4.0
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
func GetARWalkingZoneTransform(planeTransform: simd_float4x4, cameraTransform: simd_float4x4) -> simd_float4x4 {
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

func GetCameraFloorDstance(floorTransform: simd_float4x4, cameraTransform: simd_float4x4) -> Float {
    let cameraPoint = cameraTransform[3]
    // transform cameraPoin in local coordinates to floorTansoform coordinates and take the y coordinate as distance
    let cameraPointwrtFloor = floorTransform.inverse * cameraPoint
    return cameraPointwrtFloor[1]
}
