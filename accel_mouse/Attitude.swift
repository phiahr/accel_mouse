//
//  Attitude.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 03.10.22.
//

import Foundation
import CoreMotion

struct Attitude: Codable {
    let pitch: Double
    let roll: Double
    let yaw: Double
    init(attitude: CMAttitude){
        // in degrees
        pitch = attitude.pitch * 180 / .pi
        roll = attitude.roll * 180 / .pi
        yaw = attitude.yaw * 180 / .pi
    }
}
