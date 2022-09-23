//
//  FloorMapManager.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import SwiftUI

class FloorMapManager: IndoorMapManagerProtocol {
    typealias V = FloorMapView
    func getMap() -> FloorMapView {
        FloorMapView()
    }

    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> Path {
        var boxPath = Path()
        boxPath.move(to: source)
        boxPath.addLine(to: destination)
        return boxPath
    }
}

struct FloorMapView: View {
    var body: some View {
        Image("5AFloorPlan")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

struct FloorMapView_Previews: PreviewProvider {
    static var previews: some View {
        FloorMapView()
    }
}
