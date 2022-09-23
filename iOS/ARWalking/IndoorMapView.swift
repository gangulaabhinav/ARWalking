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
    // All dimensons in meters
    static let SourcePoint = CGPoint(x: 435, y: 237)
    static let DestinationPoint = CGPoint(x: 205, y: 352)

    static let SourceDestinationPathLineWidth = 8.0
    static let SourcePointColor: Color = .blue
    static let DestinationPointColor: Color = .red
    static let PointDrawSize = 12.0
    static let SourceDestinationPathColor: Color = .blue

    //let indoorMapManager = FloorMapManager()
    let indoorMapManager = MLCPDemoMapManager()

    var body: some View {
        ZStack {
            indoorMapManager.getMap()
            Canvas { context, size in
                context.fill(getPointDrawPath(point: IndoorMapView.SourcePoint), with: .color(IndoorMapView.SourcePointColor))
                context.fill(getPointDrawPath(point: IndoorMapView.DestinationPoint), with: .color(IndoorMapView.DestinationPointColor))
                context.stroke(indoorMapManager.getSourceToDestinationPath(source: IndoorMapView.SourcePoint, destination: IndoorMapView.DestinationPoint), with: .color(IndoorMapView.SourceDestinationPathColor), lineWidth: IndoorMapView.SourceDestinationPathLineWidth)
            }
            .edgesIgnoringSafeArea(.all)
            Circle()
                .strokeBorder(.gray, lineWidth: 4)
                .background(Circle().fill(.blue))
                .frame(width: 15, height: 15)
            
        }
    }

    func getPointDrawPath(point: CGPoint) -> Path {
        var squarePath = Path()
        squarePath.move   (to: CGPoint(x: point.x - IndoorMapView.PointDrawSize/2, y: point.y - IndoorMapView.PointDrawSize/2))
        squarePath.addLine(to: CGPoint(x: point.x + IndoorMapView.PointDrawSize/2, y: point.y - IndoorMapView.PointDrawSize/2))
        squarePath.addLine(to: CGPoint(x: point.x + IndoorMapView.PointDrawSize/2, y: point.y + IndoorMapView.PointDrawSize/2))
        squarePath.addLine(to: CGPoint(x: point.x - IndoorMapView.PointDrawSize/2, y: point.y + IndoorMapView.PointDrawSize/2))
        return squarePath
    }
}

struct IndoorMapView_Previews: PreviewProvider {
    static var previews: some View {
        IndoorMapView()
    }
}
