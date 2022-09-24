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

    func getMapScale() -> CGFloat {
        return 10.0
    }

    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> [CGPoint] {
        return [CGPoint(x: 51.0, y: 48.0),
                CGPoint(x: 51.0, y: 42.0),
                CGPoint(x: 24.0, y: 42.0),
                CGPoint(x: 24.0, y: 25.0)]
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
