//
//  DemoMapView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 20/09/22.
//

import SwiftUI

// Note: All the calculations are done in meters

struct DemoBoothsBox { // A row of booths for a demo booths box that can be drawn on map as a single block
    let x: CGFloat // Center x of the DemoBoothsBox
    let y: CGFloat // Center y of the DemoBoothsBox
    let width: CGFloat // Width of DemoBoothsBox = Width of 1 booth. In x directino
    let length: CGFloat // Length of DemoBoothsBox = Length of 1 booth * No. of booths. In y directions
}

extension DemoBoothsBox {
    init(x: CGFloat) {
        self.x = x
        self.y = 300.0 // Assuming all boxes have same y center location
        width = 20.0 // Width of a booth
        length = 320.0 // Length of all booths combined in a row
    }
}

struct DemoMapView: View {
    static let SourcePoint = CGPoint(x: 435, y: 237)
    static let DestinationPoint = CGPoint(x: 205, y: 352)
    static let SourcePointColor: Color = .blue
    static let DestinationPointColor: Color = .red
    static let PointDrawSize = 12.0
    static let SourceDestinationPathColor: Color = .blue
    static let SourceDestinationPathLineWidth = 8.0
    static let SourceDestinationPathOffset = 10.0 // Path offset on borders

    static let CanvsBackground: Color = Color(.sRGB, red: 230/255, green: 240/255, blue: 1, opacity: 1.0)
    static let DemoBoothsColor: Color = .black

    let demoBoxesList = [
        DemoBoothsBox(x: 50.0 ),
        DemoBoothsBox(x: 90.0 ),
        DemoBoothsBox(x: 130.0),
        DemoBoothsBox(x: 170.0),
        DemoBoothsBox(x: 210.0),
        DemoBoothsBox(x: 250.0),
        DemoBoothsBox(x: 290.0),
        DemoBoothsBox(x: 330.0),
        DemoBoothsBox(x: 370.0),
        DemoBoothsBox(x: 410.0),
        DemoBoothsBox(x: 450.0),
        DemoBoothsBox(x: 490.0),
        DemoBoothsBox(x: 530.0),
    ]

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        Canvas { context, size in
            // Draw background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(DemoMapView.CanvsBackground))
            
            // Draw a boxes
            for box in demoBoxesList {
                context.fill(getDemoBoothsBoxDrawPath(box: box), with: .color(DemoMapView.DemoBoothsColor))
            }
            context.fill(getPointDrawPath(point: DemoMapView.SourcePoint), with: .color(DemoMapView.SourcePointColor))
            context.fill(getPointDrawPath(point: DemoMapView.DestinationPoint), with: .color(DemoMapView.DestinationPointColor))
            context.stroke(getSourceToDestinationPath(source: DemoMapView.SourcePoint, destination: DemoMapView.DestinationPoint), with: .color(DemoMapView.SourceDestinationPathColor), lineWidth: DemoMapView.SourceDestinationPathLineWidth)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func getDemoBoothsBoxDrawPath(box: DemoBoothsBox) -> Path {
        var boxPath = Path()
        boxPath.move(to: CGPoint(x: box.x - box.width/2, y: box.y - box.length/2))
        boxPath.addLine(to: CGPoint(x: box.x + box.width/2, y: box.y - box.length/2))
        boxPath.addLine(to: CGPoint(x: box.x + box.width/2, y: box.y + box.length/2))
        boxPath.addLine(to: CGPoint(x: box.x - box.width/2, y: box.y + box.length/2))
        return boxPath
    }

    func getPointDrawPath(point: CGPoint) -> Path {
        var squarePath = Path()
        squarePath.move(to: CGPoint(x: point.x - DemoMapView.PointDrawSize/2, y: point.y - DemoMapView.PointDrawSize/2))
        squarePath.addLine(to: CGPoint(x: point.x + DemoMapView.PointDrawSize/2, y: point.y - DemoMapView.PointDrawSize/2))
        squarePath.addLine(to: CGPoint(x: point.x + DemoMapView.PointDrawSize/2, y: point.y + DemoMapView.PointDrawSize/2))
        squarePath.addLine(to: CGPoint(x: point.x - DemoMapView.PointDrawSize/2, y: point.y + DemoMapView.PointDrawSize/2))
        return squarePath
    }

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

    func getSourceToDestinationPath(source: CGPoint, destination: CGPoint) -> Path {
        var path = Path()
        let projectedSource = getProjectedPointInLaneCenter(point: source)
        let projectedDestination = getProjectedPointInLaneCenter(point: destination)
        path.move(to: CGPoint(x: projectedSource.x, y: projectedSource.y)) // add projected source

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
            let firstTurnPointTop = CGPoint(x: projectedSource.x, y: demoBoxesList[sourceDestinationFirstBox].y - demoBoxesList[sourceDestinationFirstBox].length/2 - DemoMapView.SourceDestinationPathOffset)
            let secondTurnPointTop = CGPoint(x: projectedDestination.x, y: demoBoxesList[destinationSourceFirstBox].y - demoBoxesList[destinationSourceFirstBox].length/2 - DemoMapView.SourceDestinationPathOffset)
            let topPathDistance = getPathDistance(point: projectedSource, point1: firstTurnPointTop, point2: secondTurnPointTop, point3: projectedDestination)

            // Calculating path from bottom
            let firstTurnPointBottom = CGPoint(x: projectedSource.x, y: demoBoxesList[sourceDestinationFirstBox].y + demoBoxesList[sourceDestinationFirstBox].length/2 + DemoMapView.SourceDestinationPathOffset)
            let secondTurnPointBottom = CGPoint(x: projectedDestination.x, y: demoBoxesList[destinationSourceFirstBox].y + demoBoxesList[destinationSourceFirstBox].length/2 + DemoMapView.SourceDestinationPathOffset)
            let bottomPathDistance = getPathDistance(point: projectedSource, point1: firstTurnPointBottom, point2: secondTurnPointBottom, point3: projectedDestination)
            
            if topPathDistance < bottomPathDistance {
                path.addLine(to: firstTurnPointTop)
                path.addLine(to: secondTurnPointTop)
            } else {
                path.addLine(to: firstTurnPointBottom)
                path.addLine(to: secondTurnPointBottom)
            }
        }
        
        path.addLine(to: CGPoint(x: projectedDestination.x, y: projectedDestination.y)) // add projected destianation
        return path
    }

    // Project a point to the center of lanes (walkways). Helpful is location has error and falls inside booths
    func getProjectedPointInLaneCenter(point : CGPoint) -> CGPoint {
        let totalBoxes = demoBoxesList.count
        let boxIndex = getBoxIndexToRightOfPoint(point: point)

        var projectedX = point.x
        if boxIndex <= 0 { // befor first box,
            projectedX = demoBoxesList[boxIndex].x - demoBoxesList[boxIndex].width/2 - DemoMapView.SourceDestinationPathOffset
        } else if boxIndex >= totalBoxes {
            projectedX = demoBoxesList[boxIndex - 1].x + demoBoxesList[boxIndex - 1].width/2 + DemoMapView.SourceDestinationPathOffset
        } else {
            projectedX = (demoBoxesList[boxIndex - 1].x + demoBoxesList[boxIndex].x)/2
        }
        return CGPoint(x: projectedX, y: point.y)
    }
}

struct DemoMapView_Previews: PreviewProvider {
    static var previews: some View {
        DemoMapView()
    }
}
