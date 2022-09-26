//
//  NavigationManager.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 24/09/22.
//

import AVFoundation
import Foundation
import CoreGraphics
import UIKit

class NavigationManager: ObservableObject {
    @Published var proximityForTurn = 1.0 // meters
    @Published var isNavigating = false

    var sourceLocation = CGPoint()
    var destinationLocation = CGPoint()

    var navigationPath: [CGPoint] = []
    var completedPoints: [Bool] = []

    let synthesizer = AVSpeechSynthesizer()

    func startNavigation(from: CGPoint, to: CGPoint) {
        sourceLocation = from
        destinationLocation = to
        isNavigating = true
    }

    func setNavigationPath(navigationPath: [CGPoint]) {
        // Hack: This is being called everytime the view is updated. Returning if navigationPath is not empty
        if !self.navigationPath.isEmpty || navigationPath.count < 1 {
             return
        }
        self.navigationPath = navigationPath
        let routeString = "Route calculated. Estimated time 1 minute to destination. Start walking"
        // Note: This delay is required for the notificaiton ot be announced reliably. Else, other notifications are overtaking these announcements
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.speakString(string: routeString)
        }
        
        // Mark the source as completed destinations
        completedPoints.removeAll()
        for _ in navigationPath {
            completedPoints.append(false)
        }
        completedPoints[0] = true
    }

    func onLocationUpdated(x: CGFloat, y: CGFloat) {
        if !isNavigating {
            return
        }

        var proximityPointIndex = -1
        for (index, point) in navigationPath.enumerated() {
            let distance = point.distance(x: x, y: y)
            if (distance < proximityForTurn) && completedPoints[index] == false {
                proximityPointIndex = index
                completedPoints[index] = true
            }
        }
        
        // If we are near a turn that hasn't been visited previously, announce it
        if proximityPointIndex != -1 {
            var turnAnnouncement = "Turn now"
            if proximityPointIndex == navigationPath.count - 1 {
                turnAnnouncement = "Reached destination"
            } else {
                let arrivalVector = navigationPath[proximityPointIndex].getVector(from: navigationPath[proximityPointIndex - 1])
                let destinationVector = navigationPath[proximityPointIndex].getVector(to: navigationPath[proximityPointIndex + 1])
                let crossProduct = (arrivalVector.dx * destinationVector.dy) - (arrivalVector.dy * destinationVector.dx)
                if crossProduct < 0 { // If the cross product is -ve, anti-clockwise, means left turn
                    turnAnnouncement = "Turn left"
                } else {
                    turnAnnouncement = "Turn right"
                }
            }
            speakString(string: turnAnnouncement)
        }
        return
    }

    func speakString(string: String) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: string)
        } else {
            // Create an utterance.
            let utterance = AVSpeechUtterance(string: string)

            // Configure the utterance.
            utterance.rate = 0.5
            utterance.pitchMultiplier = 0.8
            utterance.postUtteranceDelay = 0.2
            utterance.volume = 0.8

            // Retrieve the British English voice.
            let voice = AVSpeechSynthesisVoice(language: "en-US")

            // Assign the voice to the utterance.
            utterance.voice = voice
            // Tell the synthesizer to speak the utterance.
            synthesizer.speak(utterance)
        }
    }
}
