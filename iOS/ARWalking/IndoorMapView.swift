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
    static let SourceLocation = CGPoint(x: 25, y: 23)
    // All dimensons in meters
    static let SourceDestinationPathLineWidth = 4.0
    static let SourcePointColor: Color = .blue
    static let DestinationPointColor: Color = .red
    static let PointDrawSize = 12.0
    static let SourceDestinationPathColor: Color = .blue

    let indoorMapManager = FloorMapManager()
    //let indoorMapManager = MLCPDemoMapManager()

    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var currentLocationData: CurrentLocationData

    @State var showSettings = false
    @State private var locationOffsetX = 25.0
    @State private var locationOffsetY = 25.0
    @State private var referenceBoxSizeX = 20.0
    @State private var referenceBoxSizeY = 20.0
    @State private var overrideMapScale = 10.0

    init(currentLocationData: CurrentLocationData, navigationManager: NavigationManager) {
        self.currentLocationData = currentLocationData
        self.navigationManager = navigationManager
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            indoorMapManager.getMap()
            if navigationManager.isNavigating {
                Canvas { context, size in
                    context.fill(getPointDrawPath(point: (navigationManager.sourceLocation + CGPoint(x: locationOffsetX, y: locationOffsetY)) * getScale()), with: .color(IndoorMapView.SourcePointColor))
                    context.fill(getPointDrawPath(point: (navigationManager.destinationLocation + CGPoint(x: locationOffsetX, y: locationOffsetY)) * getScale()), with: .color(IndoorMapView.DestinationPointColor))
                    context.stroke(getSourceToDestinationPath(), with: .color(IndoorMapView.SourceDestinationPathColor), lineWidth: IndoorMapView.SourceDestinationPathLineWidth)
                }
                .edgesIgnoringSafeArea(.all)
            }

            VStack (alignment: .leading) {
                Toggle("", isOn: $showSettings)
                    .labelsHidden()
                if showSettings {
                    Stepper("locationOffsetX: " + String(format: "%.1f", locationOffsetX), value: $locationOffsetX, step: 0.1)
                    Stepper("locationOffsetY: " + String(format: "%.1f", locationOffsetY), value: $locationOffsetY, step: 0.1)
                    Stepper("referenceBoxSizeX: " + String(format: "%.1f", referenceBoxSizeX), value: $referenceBoxSizeX, step: 0.1)
                    Stepper("referenceBoxSizeY: " + String(format: "%.1f", referenceBoxSizeY), value: $referenceBoxSizeY, step: 0.1)
                    Stepper("overrideMapScale: " + String(format: "%.1f", overrideMapScale), value: $overrideMapScale, step: 0.1)
                }
            }
            .scaledToFit()
            .foregroundColor(.red)

            if showSettings {
                Rectangle()
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: referenceBoxSizeX * getScale(), height: referenceBoxSizeY * getScale())
                    .position(CGPoint(x: locationOffsetX, y: locationOffsetY) * getScale() + CGPoint(x: 0.5*referenceBoxSizeX * getScale(), y: 0.5*referenceBoxSizeY * getScale()))
            }
            Circle()
                .strokeBorder(.gray, lineWidth: 4)
                .background(Circle().fill(.blue))
                .frame(width: 15, height: 15)
                .position((CGPoint(x: currentLocationData.x, y: currentLocationData.y) + CGPoint(x: locationOffsetX, y: locationOffsetY)) * getScale())
        }
    }

    func getScale() -> CGFloat {
        if showSettings {
            return overrideMapScale
        } else {
            return indoorMapManager.getMapScale()
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
        let source = CGPoint(x: currentLocationData.x, y: currentLocationData.y) + CGPoint(x: locationOffsetX, y: locationOffsetY)
        let destination = navigationManager.destinationLocation + CGPoint(x: locationOffsetX, y: locationOffsetY)

        let pathPoints = indoorMapManager.getSourceToDestinationPath(source: source, destination: destination)
        // Convert to location coordinates from MapCoordinates to Location coordinatesa and update navigationManager
        var locationPathPoints: [CGPoint] = []
        for point in pathPoints {
            locationPathPoints.append(point - CGPoint(x: locationOffsetX, y: locationOffsetY))
        }
        navigationManager.setNavigationPath(navigationPath: locationPathPoints)

        var path = Path()
        if pathPoints.count < 2 {
            path.move   (to: source * getScale())
            path.addLine(to: destination * getScale())
        } else {
            for (index, point) in pathPoints.enumerated() {
                if index == 0 {
                    path.move   (to: pathPoints[0] * getScale())
                } else {
                    path.addLine(to: point * getScale())
                }
            }
        }
        return path
    }
}

struct IndoorMapView_Previews: PreviewProvider {
    static var previews: some View {
        IndoorMapView(currentLocationData: CurrentLocationData(navigationManager: NavigationManager()), navigationManager: NavigationManager())
    }
}
