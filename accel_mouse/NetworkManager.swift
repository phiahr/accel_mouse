//
//  NetworkManager.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 01.10.22.
//

import Foundation
import CoreMotion

class NetworkManager: NSObject, URLSessionDelegate
{
    let manager = CMMotionManager()
    var ipAddress = "172.20.10.2"
    let frequency = 0.2 // 0.01
    private var webSocket : URLSessionWebSocketTask!
    
    
    var audioLevel : Float = 0.0
    
    var mouseTap = false
    
    override init(){
        super.init()
        listenVolumeButton()
        
        //        handleMotionUpdates()
        //        startAccelerometers()
        //        startGyrometer()
        
    }
    
    
    //MARK: Network management
    
    func connect()
    {
        print("Connect to Server")
        
        //Session
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        
        //Server API
        let url = URL(string:  "ws://"+ipAddress+":8000/ws")
        
        //Socket
        webSocket = session.webSocketTask(with: url!)
        
        //Connect and hanles handshake
        webSocket.resume()
        startMotionEstimates()
//        startMotionUpdates()
//        startMagnetometer()
//        startGyrometer()
//        startAccelerometers()
        //        receive()
    }
    
    func disconnect()
    {
        print("close session")
        stopMotionUpdates()
        webSocket?.cancel(with: .goingAway, reason: "You've Closed The Connection".data(using: .utf8))
    }
    
    func send(uploadData: Data)
    {
        let workItem = DispatchWorkItem{
            
            self.webSocket?.send(URLSessionWebSocketTask.Message.data(uploadData), completionHandler: { error in
                if error != nil {
                    print(error)
                }
            })
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now(), execute: workItem)
    }
    
    func receive()
    {
        /// This Recurring will keep us connected to the server
        /*
         - Create a workItem
         - Add it to the Queue
         */
        
        let workItem = DispatchWorkItem{ [weak self] in
            
            self?.webSocket?.receive(completionHandler: { result in
                
                
                switch result {
                case .success(let message):
                    
                    switch message {
                        
                    case .data(let data):
                        print("Data received \(data)")
                        
                    case .string(let strMessgae):
                        print("String received \(strMessgae)")
                        
                    default:
                        break
                    }
                    
                case .failure(let error):
                    print("Error Receiving \(error)")
                }
                // Creates the Recurrsion
                self?.receive()
            })
        }
        DispatchQueue.global().asyncAfter(deadline: .now(), execute: workItem)
    }
    
    
    
    
    //MARK: Motion Management
    
    
    func startMotionUpdates()
    {
        handleMotionUpdates()
    }
    
    func stopMotionUpdates()
    {
        print("Stop motion Updates")
        manager.stopDeviceMotionUpdates()
        stopMotionEstimates()
    }
    
    
    var roll: Double!
    var pitch: Double!
    func handleMotionUpdates()
    {
        
        manager.deviceMotionUpdateInterval = frequency
        print("Handle motion updates")
        
        //        var old_vel_x = 0.0
        //        var old_dist_x = 0.0
        manager.startDeviceMotionUpdates(to: .main) { (motion, error) in
            // Handle device motion updates
            // Get accelerometer sensor data
            let a_x = motion?.userAcceleration.x
            let a_y = motion?.userAcceleration.y
            let a_z = motion?.userAcceleration.z
            
            // Get gyroscope sensor data
            let r = motion?.rotationRate.x
            let p = motion?.rotationRate.y
            let q = motion?.rotationRate.z
            
            // Get magnetometer sensor data
            let accuracy = motion?.magneticField.accuracy
            let m_x = motion?.magneticField.field.x
            let m_y = motion?.magneticField.field.y
            let m_z = motion?.magneticField.field.z
            print("Accuracy: ", accuracy?.rawValue)
            // Get attitude orientation
            self.pitch = motion!.attitude.pitch
            self.roll = motion!.attitude.roll
            let yaw = motion!.attitude.yaw
            
            // Get gravity vector
            //            let g_x = motion?.gravity.x
            //            let g_y = motion?.gravity.y
            //            let g_z = motion?.gravity.z
            //
            //            var vel_x = old_vel_x + a_x! * self.frequency
            //            var dist_x = old_dist_x + vel_x * self.frequency
            //            print("pitch: ", pitch!, "roll: ", roll!, "yaw: ", yaw!)
            //            print("yaw: ", (yaw! * 180 / .pi))
            //            print(a_x)
            
            //            old_vel_x = vel_x
            //            old_dist_x = dist_x
            //            print("yaw: ", yaw)
            var D: Double
            D = 2 + (31/60) + (48/3600)
            D = D * (.pi/180)
            
            
            
            print(self.roll)
            print(cos(self.roll))
            
            print(m_y!)
            print(m_x!)
            print(m_z!)
            //            print(sin(roll)*m_z)
            //            let nom = cos(roll)*m_y - sin(roll)*m_z
            ////            print(nom)
            //            let denom = cos(pitch)*m_x+sin(roll)*sin(pitch)*m_y+cos(roll)*sin(pitch)*m_z
            ////            print(denom)
            ////            print(D)
            //
            //
            //            let psi_hat = D-atan(nom/denom)
            //            print("yaw: ", yaw, "estim yaw: ", psi_hat)
            
            let estimated_pitch = asin(-a_y!)
            print("estimated pitch: ", estimated_pitch, " ", self.pitch)
            let estimated_roll = atan(-a_x!/a_z!)
            let estimated_yaw = self.old_yaw + (-q!) * self.frequency
            self.old_yaw = estimated_yaw
            print("Estim yaw, ", estimated_yaw * 180 / .pi)
            print("real yaw", yaw * 180 / .pi)
//            let attitude = Attitude(attitude: motion!.attitude)
            let attitude = Attitude(roll: estimated_roll, pitch: estimated_pitch, yaw: -estimated_yaw)
            guard let data = try? JSONEncoder().encode(attitude) else {
                return
            }
            self.send(uploadData: data)
        }
    }
    
    func startMotionEstimates()
    {
        if self.motion2.isAccelerometerAvailable && self.motion2.isGyroAvailable
        {
            self.motion2.accelerometerUpdateInterval = frequency
            self.motion2.gyroUpdateInterval = frequency
            self.motion2.magnetometerUpdateInterval = frequency
            
            self.motion2.startAccelerometerUpdates()
            self.motion2.startGyroUpdates()
            self.motion2.startMagnetometerUpdates()
            
            self.timer = Timer(fire: Date(), interval: (frequency),
                               repeats: true, block: { (timer) in
                if let accelData = self.motion2.accelerometerData, let gyroData = self.motion2.gyroData, let magData = self.motion2.magnetometerData
                {
                    let a_x = accelData.acceleration.x
                    let a_y = accelData.acceleration.y
                    let a_z = accelData.acceleration.z
                    
                    _ = gyroData.rotationRate.x
                    _ = gyroData.rotationRate.y
                    let g_z = gyroData.rotationRate.z
                    
                    let m_x = magData.magneticField.x
                    let m_y = magData.magneticField.y
                    let m_z = magData.magneticField.z
                    
                    let estimated_pitch = asin(-a_y)
                    let estimated_roll = atan(-a_x/a_z)
                    
                    let M_x = m_x*cos(estimated_pitch)+m_z*sin(estimated_pitch)
                    let M_y = m_x*sin(estimated_roll)*sin(estimated_pitch)+m_y*cos(estimated_roll)-m_z*sin(estimated_roll)*cos(estimated_pitch)

                    let psi_hat = atan(M_y/M_x)
                    
                    
                    let estimated_yaw = self.old_yaw2 + g_z * self.frequency
                    
                    self.old_yaw2 = estimated_yaw
                    print(estimated_yaw * 180.0 / .pi, " <> ", psi_hat * 180.0 / .pi)
                    let rotation = atan2(a_x, a_y) - .pi
                    print(rotation * 180.0 / .pi)
                    
//                    print(magData)
                    
                    let attitude = Attitude(roll: estimated_roll, pitch: estimated_pitch, yaw: estimated_yaw)
                    guard let data = try? JSONEncoder().encode(attitude) else {
                        return
                    }
                    self.send(uploadData: data)
                }
            })
        }
        RunLoop.current.add(self.timer, forMode: .default)
    }
    
    func stopMotionEstimates()
    {
        self.motion2.stopAccelerometerUpdates()
        self.motion2.stopGyroUpdates()
        self.motion2.stopMagnetometerUpdates()
        timer.invalidate()
    }
    
    let motion2 = CMMotionManager()
    var timer: Timer!
    var old_yaw = 0.0
    func startAccelerometers() {
        // Make sure the accelerometer hardware is available.
        if self.motion2.isAccelerometerAvailable {
            self.motion2.accelerometerUpdateInterval = frequency  // 60 Hz
            self.motion2.startAccelerometerUpdates()
            //           self.motion2.startAccelerometerUpdates(to: .main) { (motion, error) in
            //       }
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: (frequency),
                               repeats: true, block: { (timer) in
                // Get the accelerometer data.
                if let data = self.motion2.accelerometerData {
                    let x = data.acceleration.x
                    let y = data.acceleration.y
                    let z = data.acceleration.z
                    let estimated_pitch = asin(-y)
                    let estimated_roll = atan(-x/z)
                    print("estimated roll: ", estimated_pitch)
                    // Use the accelerometer data in your app.
                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer, forMode: .default)
        }
    }
    
    
    // Yaw is biased from starting position??
    var old_yaw2 = 0.0
    func startGyrometer() {
        if self.motion2.isGyroAvailable {
            self.motion2.gyroUpdateInterval = frequency  // 60 Hz
            self.motion2.startGyroUpdates()
            
            // Configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: (frequency),
                               repeats: true, block: { (timer) in
                // Get the accelerometer data.
                if let data = self.motion2.gyroData {
                    let x = data.rotationRate.x
                    let y = -data.rotationRate.y
                    let z = -data.rotationRate.z
                    
                    let estimated_yaw = self.old_yaw2 + z * self.frequency
                    self.old_yaw2 = estimated_yaw
                    print("estimated yaw: ", estimated_yaw*180 / .pi)
                    
                    
                    // Use the accelerometer data in your app.
                }
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer, forMode: .default)
        }
    }
    
    func startMagnetometer() {
        if self.motion2.isMagnetometerAvailable {
            self.motion2.magnetometerUpdateInterval = frequency  // 60 Hz
            self.motion2.startMagnetometerUpdates(to: .main, withHandler: {(motion, error) in
                // Get the accelerometer data.
                if let data = self.motion2.magnetometerData {
                    let m_x = data.magneticField.x
                    let m_y = -data.magneticField.y
                    let m_z = -data.magneticField.z
                    var D: Double
                    D = 2 + (31/60) + (48/3600)
                    D = D * (.pi/180)
                    
                    let nom = cos(self.roll)*m_y - sin(self.roll)*m_z
                    let denom = cos(self.pitch)*m_x+sin(self.roll)*sin(self.pitch)*m_y+cos(self.roll)*sin(self.pitch)*m_z
                    
                    let psi_hat = D-atan(nom/denom)
                    print("estim yaw: ", psi_hat * (180 / .pi))
                }
            })
        }
    }
    
    //MARK: URLSESSION Protocols
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Connected to server")
        self.receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Disconnect from Server \(reason)")
    }
}
