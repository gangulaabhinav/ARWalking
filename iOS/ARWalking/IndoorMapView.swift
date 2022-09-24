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
    static let LocationOffset = CGPoint(x: 25, y: 25) // What does 0,0 world location correspond to on the map
    static let CurrentLocation = CGPoint(x: 0, y: 0)
    static let SourceLocation = CGPoint(x: 25, y: 23)
    static let DestinationLocation = CGPoint(x: -4.0, y: 0.0)
    static let ReferenceBoxSize = CGSize(width: 20.0, height: 20.0) // Rectangular to be drawn as reference on the map starting from (0,0) point

    static let SourceDestinationPathLineWidth = 4.0
    static let SourcePointColor: Color = .blue
    static let DestinationPointColor: Color = .red
    static let PointDrawSize = 12.0
    static let SourceDestinationPathColor: Color = .blue

    let indoorMapManager = FloorMapManager()
    //let indoorMapManager = MLCPDemoMapManager()

    @State var showSettings = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            indoorMapManager.getMap()
            Canvas { context, size in
                context.fill(getPointDrawPath(point: (IndoorMapView.SourceLocation + IndoorMapView.LocationOffset)*indoorMapManager.getMapScale()), with: .color(IndoorMapView.SourcePointColor))
                context.fill(getPointDrawPath(point: (IndoorMapView.DestinationLocation + IndoorMapView.LocationOffset)*indoorMapManager.getMapScale()), with: .color(IndoorMapView.DestinationPointColor))
                context.stroke(getSourceToDestinationPath(), with: .color(IndoorMapView.SourceDestinationPathColor), lineWidth: IndoorMapView.SourceDestinationPathLineWidth)
            }
            .edgesIgnoringSafeArea(.all)
            Toggle("", isOn: $showSettings)
                .labelsHidden()
            if showSettings {
                Rectangle()
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: IndoorMapView.ReferenceBoxSize.width*indoorMapManager.getMapScale(), height: IndoorMapView.ReferenceBoxSize.height*indoorMapManager.getMapScale())
                    .position(IndoorMapView.LocationOffset*indoorMapManager.getMapScale() + CGPoint(x: 0.5*IndoorMapView.ReferenceBoxSize.width*indoorMapManager.getMapScale(), y: 0.5*IndoorMapView.ReferenceBoxSize.height*indoorMapManager.getMapScale()))
            }
            Circle()
                .strokeBorder(.gray, lineWidth: 4)
                .background(Circle().fill(.blue))
                .frame(width: 15, height: 15)
                .position((IndoorMapView.CurrentLocation + IndoorMapView.LocationOffset)*indoorMapManager.getMapScale())
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

    func getSourceToDestinationPath() -> Path {
        let source = IndoorMapView.SourceLocation + IndoorMapView.LocationOffset
        let destination = IndoorMapView.DestinationLocation + IndoorMapView.LocationOffset
        let pathPoints = indoorMapManager.getSourceToDestinationPath(source: source, destination: destination)

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
