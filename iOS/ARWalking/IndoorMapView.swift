//
//  IndoorMapView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 19/09/22.
//

import SwiftUI

protocol IndoorMapManagerProtocol {
    associatedtype V: View   // Create a new type that conforms to View
    func getMap() -> V
    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> Path
}

struct IndoorMapView: View {
    //let indoorMapManager = FloorMapManager()
    let indoorMapManager = MLCPDemoMapManager()

    var body: some View {
        ZStack {
            indoorMapManager.getMap()
            Circle()
                .strokeBorder(.gray, lineWidth: 4)
                .background(Circle().fill(.blue))
                .frame(width: 15, height: 15)
            
        }
    }
}

struct IndoorMapView_Previews: PreviewProvider {
    static var previews: some View {
        IndoorMapView()
    }
}
