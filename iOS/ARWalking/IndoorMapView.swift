//
//  IndoorMapView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 19/09/22.
//

import SwiftUI

// All dimensions are in meters

protocol IndoorMapManagerProtocol {
    associatedtype V: View   // Create a new type that conforms to View
    func getMap() -> V
    func getMapScale() -> CGFloat
    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> [CGPoint]
}

struct IndoorMapView: View {
    // All dimensons in meters
    static let SourcePoint = CGPoint(x: 43.5, y: 23.7)
    static let DestinationPoint = CGPoint(x: 20.5, y: 35.2)

    static let SourceDestinationPathLineWidth = 8.0
    static let SourcePointColor: Color = .blue
    static let DestinationPointColor: Color = .red
    static let PointDrawSize = 12.0
    static let SourceDestinationPathColor: Color = .blue

    let indoorMapManager = FloorMapManager()
    //let indoorMapManager = MLCPDemoMapManager()

    var body: some View {
        ZStack {
            indoorMapManager.getMap()
            Canvas { context, size in
                context.fill(getPointDrawPath(point: IndoorMapView.SourcePoint*indoorMapManager.getMapScale()), with: .color(IndoorMapView.SourcePointColor))
                context.fill(getPointDrawPath(point: IndoorMapView.DestinationPoint*indoorMapManager.getMapScale()), with: .color(IndoorMapView.DestinationPointColor))
                context.stroke(getSourceToDestinationPath(source: IndoorMapView.SourcePoint, destination: IndoorMapView.DestinationPoint), with: .color(IndoorMapView.SourceDestinationPathColor), lineWidth: IndoorMapView.SourceDestinationPathLineWidth)
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

    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> Path {
        let pathPoints = indoorMapManager.getSourceToDestinationPath(source: IndoorMapView.SourcePoint, destination: IndoorMapView.DestinationPoint)

        var path = Path()
        if pathPoints.count < 2 {
            path.move   (to: source*indoorMapManager.getMapScale())
            path.addLine(to: destination*indoorMapManager.getMapScale())
        } else {
            for (index, point) in pathPoints.enumerated() {
                if index == 0 {
                    path.move   (to: pathPoints[0]*indoorMapManager.getMapScale())
                } else {
                    path.addLine(to: point*indoorMapManager.getMapScale())
                }
            }
        }
        return path
    }
}

struct IndoorMapView_Previews: PreviewProvider {
    static var previews: some View {
        IndoorMapView()
    }
}
