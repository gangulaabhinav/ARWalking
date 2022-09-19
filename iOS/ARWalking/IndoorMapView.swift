//
//  IndoorMapView.swift
//  ARWalking
//
//  Created by Abhinav Gangula on 19/09/22.
//

import SwiftUI

struct IndoorMapView: View {
    var body: some View {
        ZStack {
            Image("Example-House-Floor-Plan-1")
                .resizable()
                .aspectRatio(contentMode: .fit)
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
