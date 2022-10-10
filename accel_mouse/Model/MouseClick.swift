//
//  MouseClick.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 03.10.22.
//

import Foundation

struct MouseClick: Codable {
    var leftMouseClick: Bool
    var rightMouseClick: Bool
    var mouseDoubleClick: Bool
    var scroll: Double
}
