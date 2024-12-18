//
//  ScreenSizeModel.swift
//  deadline
//
//  Created by Kangmin on 11/19/24.
//

import Foundation
import SwiftUI

class ScreenSizeModel: ObservableObject {
    @Published var screenSize: CGSize = .zero
    
    func updateSize(newSize: CGSize) {
        screenSize = newSize
        print("Screen size updated: \(screenSize)")
    }
}
