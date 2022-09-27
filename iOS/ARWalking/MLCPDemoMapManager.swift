//
//  MLCPDemoMapManager.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 20/09/22.
//

import SwiftUI

// Note: All the calculations are done in meters

class MLCPDemoMapManager: IndoorMapManagerProtocol {
    typealias V = DemoMapView
    let demoMapData = DemoMapData()
    func getMap() -> DemoMapView {
        DemoMapView(demoMapData: demoMapData, viewScale: getMapScale())
    }

    func getMapScale() -> CGFloat { // 1 meters to points on view
        return 10.0
    }

    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> [CGPoint] {
        demoMapData.getSourceToDestinationPath(source: source, destination: destination)
    }

    func getDestinations() -> [String: CGPoint] {
        demoMapData.demoDestinations
    }
}

struct DemoBoothsBox { // A row of booths for a demo booths box that can be drawn on map as a single block
    let x: CGFloat // Center x of the DemoBoothsBox
    let y: CGFloat // Center y of the DemoBoothsBox
    let width: CGFloat // Width of DemoBoothsBox = Width of 1 booth. In x directino
    let length: CGFloat // Length of DemoBoothsBox = Length of 1 booth * No. of booths. In y directions
}

extension DemoBoothsBox {
    init(x: CGFloat) {
        self.x = x
        self.y = 15.0 // Assuming all boxes have same y center location
        width = 3.0 // Width of a booth
        length = 13.0 // Length of all booths combined in a row
    }
}

struct DemoMapData {
    static let SourceDestinationPathOffset = 1.0 // Path offset on borders

    // All dimensons in meters
    let demoBoxesList = [
        DemoBoothsBox(x:  4.0),
        DemoBoothsBox(x: 11.0),
        DemoBoothsBox(x: 18.0),
        DemoBoothsBox(x: 25.0),
        DemoBoothsBox(x: 32.0),
        DemoBoothsBox(x: 39.0),
        DemoBoothsBox(x: 46.0),
        DemoBoothsBox(x: 53.0),
    ]

    let demoDestinations = ["Sample": CGPoint(x: 10, y: 15)]
    func getBoxIndexToRightOfPoint(point : CGPoint) -> Int {
        let totalBoxes = demoBoxesList.count
        var pointXIndex = totalBoxes
        for (index, box) in demoBoxesList.enumerated() { // Finds the box which is to the right of point
            if point.x < box.x {
                pointXIndex = index
                break
            }
        }
        return pointXIndex
    }

    func getPathDistance(point : CGPoint, point1 : CGPoint, point2 : CGPoint, point3 : CGPoint) -> CGFloat {
        var distance = sqrt((point.x - point1.x) * (point.x - point1.x) + (point.y - point1.y) * (point.y - point1.y))
        distance += sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y))
        distance += sqrt((point2.x - point3.x) * (point2.x - point3.x) + (point2.y - point3.y) * (point2.y - point3.y))
        return distance
    }

    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> [CGPoint] {
        let projectedSource = getProjectedPointInLaneCenter(point: source)
        let projectedDestination = getProjectedPointInLaneCenter(point: destination)

        var pathPoints = [projectedSource] // add projected source to the path list

        // Assuming there are only two turns needed
        let sourceRightBox = getBoxIndexToRightOfPoint(point: source)
        let destinationRightBox = getBoxIndexToRightOfPoint(point: destination)
        
        if sourceRightBox != destinationRightBox { // If source and destination are not in the same box
            var sourceDestinationFirstBox = -1
            var destinationSourceFirstBox = -1
            if sourceRightBox > destinationRightBox { // source is to right of destination
                sourceDestinationFirstBox = sourceRightBox - 1
                destinationSourceFirstBox = destinationRightBox
            } else { // source is to left of destination
                sourceDestinationFirstBox = sourceRightBox
                destinationSourceFirstBox = destinationRightBox - 1
            }
            
            // Calculating path from top
            let firstTurnPointTop = CGPoint(x: projectedSource.x, y: demoBoxesList[sourceDestinationFirstBox].y - demoBoxesList[sourceDestinationFirstBox].length/2 - DemoMapData.SourceDestinationPathOffset)
            let secondTurnPointTop = CGPoint(x: projectedDestination.x, y: demoBoxesList[destinationSourceFirstBox].y - demoBoxesList[destinationSourceFirstBox].length/2 - DemoMapData.SourceDestinationPathOffset)
            let topPathDistance = getPathDistance(point: projectedSource, point1: firstTurnPointTop, point2: secondTurnPointTop, point3: projectedDestination)

            // Calculating path from bottom
            let firstTurnPointBottom = CGPoint(x: projectedSource.x, y: demoBoxesList[sourceDestinationFirstBox].y + demoBoxesList[sourceDestinationFirstBox].length/2 + DemoMapData.SourceDestinationPathOffset)
            let secondTurnPointBottom = CGPoint(x: projectedDestination.x, y: demoBoxesList[destinationSourceFirstBox].y + demoBoxesList[destinationSourceFirstBox].length/2 + DemoMapData.SourceDestinationPathOffset)
            let bottomPathDistance = getPathDistance(point: projectedSource, point1: firstTurnPointBottom, point2: secondTurnPointBottom, point3: projectedDestination)
            
            if topPathDistance < bottomPathDistance {
                pathPoints.append(firstTurnPointTop)
                pathPoints.append(secondTurnPointTop)
            } else {
                pathPoints.append(firstTurnPointBottom)
                pathPoints.append(secondTurnPointBottom)
            }
        }

        pathPoints.append(projectedDestination)
        return pathPoints
    }

    // Project a point to the center of lanes (walkways). Helpful is location has error and falls inside booths
    func getProjectedPointInLaneCenter(point : CGPoint) -> CGPoint {
        let totalBoxes = demoBoxesList.count
        let boxIndex = getBoxIndexToRightOfPoint(point: point)

        var projectedX = point.x
        if boxIndex <= 0 { // befor first box,
            projectedX = demoBoxesList[boxIndex].x - demoBoxesList[boxIndex].width/2 - DemoMapData.SourceDestinationPathOffset
        } else if boxIndex >= totalBoxes {
            projectedX = demoBoxesList[boxIndex - 1].x + demoBoxesList[boxIndex - 1].width/2 + DemoMapData.SourceDestinationPathOffset
        } else {
            projectedX = (demoBoxesList[boxIndex - 1].x + demoBoxesList[boxIndex].x)/2
        }
        return CGPoint(x: projectedX, y: point.y)
    }
}

struct DemoMapView: View {
    static let CanvsBackground: Color = Color(.sRGB, red: 230/255, green: 240/255, blue: 1, opacity: 1.0)
    static let DemoBoothsColor: Color = .gray

    let demoMapData: DemoMapData
    let viewScale: CGFloat

    init(demoMapData: DemoMapData, viewScale: CGFloat) {
        self.demoMapData = demoMapData
        self.viewScale = viewScale
    }

    var body: some View {
        Canvas { context, size in
            // Draw background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DemoMapView.CanvsBackground))
            
            // Draw a boxes
            for box in demoMapData.demoBoxesList {
                context.fill(getDemoBoothsBoxDrawPath(box: box), with: .color(DemoMapView.DemoBoothsColor))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func getDemoBoothsBoxDrawPath(box: DemoBoothsBox) -> Path {
        var boxPath = Path()
        boxPath.move   (to: CGPoint(x: box.x - box.width/2, y: box.y - box.length/2)*viewScale)
        boxPath.addLine(to: CGPoint(x: box.x + box.width/2, y: box.y - box.length/2)*viewScale)
        boxPath.addLine(to: CGPoint(x: box.x + box.width/2, y: box.y + box.length/2)*viewScale)
        boxPath.addLine(to: CGPoint(x: box.x - box.width/2, y: box.y + box.length/2)*viewScale)
        return boxPath
    }
}

struct DemoMapView_Previews: PreviewProvider {
    static var previews: some View {
        DemoMapView(demoMapData: DemoMapData(), viewScale: 10)
    }
}
