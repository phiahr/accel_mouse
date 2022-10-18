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
    var ipAddress = "172.20.10.8"
    let frequency = 0.01 // 0.01
    private var webSocket : URLSessionWebSocketTask!
    
    var yawBias = 0.0
    var realYawBias = 0.0

    var isCalibrated = false
    
    var useEstimatedValues = false
    
    var audioLevel : Float = 0.0
        
    override init(){
        super.init()
        listenVolumeButton()        
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
        
        //Connect
        webSocket.resume()
        startMotionUpdates()
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
        isCalibrated = false
    }
    
    
    var roll: Double!
    var pitch: Double!

    let tau = 0.075
    var old_roll = 0.0
    var old_pitch = 0.0
    var old_yaw = 0.0

    func handleMotionUpdates()
    {
        let k = 0.95
        let k2 = 0.2
        manager.deviceMotionUpdateInterval = frequency
        print("Handle motion updates")
        
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { (motion, error) in
            // Handle device motion updates
            guard let motion = motion else {return}

            // Get gravity vector
            let g_x = motion.gravity.x
            let g_y = motion.gravity.y
            let g_z = motion.gravity.z
            
            // Get accelerometer sensor data
            let a_y = motion.userAcceleration.x+g_x
            let a_x = -(motion.userAcceleration.y+g_y)
            let a_z = -(motion.userAcceleration.z+g_z)
            
            // Get gyroscope sensor data
            let q = -motion.rotationRate.x
            let p = motion.rotationRate.y
            let r = -motion.rotationRate.z
            
            // Get magnetometer sensor data
            let accuracy = motion.magneticField.accuracy
            let m_y = motion.magneticField.field.x
            let m_x = motion.magneticField.field.y
            let m_z = -motion.magneticField.field.z

            // Get attitude orientation
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            var yaw = motion.attitude.yaw
            
            var D: Double
            D = 2 + (31/60) + (48/3600)
            D = D * (.pi/180)
            
            let accel_pitch = asin(a_x)
            let accel_roll = atan(a_y/a_z)
            
            let gyro_roll = self.old_roll + p * self.frequency
            let gyro_pitch = self.old_pitch + q * self.frequency
            
            // worked better with just the estimated tilt from the accelerometer
            let estimated_pitch = /*k2 * gyro_pitch + (1-k) * */(accel_pitch)
            let estimated_roll = /*k2 * gyro_roll + (1-k) * */(accel_roll)

            let Xm = m_x*cos(estimated_pitch)+m_y*sin(estimated_roll)*sin(estimated_pitch)+m_z*cos(estimated_roll)*sin(estimated_pitch)
            let Ym = m_y*cos(estimated_roll)-m_z*sin(estimated_roll)
            
            var mag_yaw = D-atan2(Ym,Xm)
                        
            if !self.isCalibrated
            {
                self.yawBias = mag_yaw
                self.realYawBias = yaw
                self.isCalibrated	 = true
            }
            
            if(mag_yaw - self.yawBias < -(.pi))
            {
                mag_yaw += 2 * .pi
            }
            else if (mag_yaw - self.yawBias > .pi){
                mag_yaw -= 2 * .pi
            }

            mag_yaw -= self.yawBias
            
            let gyro_yaw = self.old_yaw + r * self.frequency
            
            let estimated_yaw = k*gyro_yaw+(1-k)*mag_yaw
            
            self.old_roll = estimated_roll
            self.old_pitch = estimated_pitch
            self.old_yaw = estimated_yaw
            
            var attitude: Attitude!
            if self.useEstimatedValues
            {
                attitude = Attitude(roll: estimated_roll, pitch: estimated_pitch, yaw: estimated_yaw)
            }
            else
            {
                yaw -= self.realYawBias
                attitude = Attitude(roll: roll, pitch: pitch, yaw: yaw)
            }
            
            guard let data = try? JSONEncoder().encode(attitude) else {
                return
            }
            self.send(uploadData: data)
        }
    }
    
    // DEPRECATED: different function to get the raw sensor data
    let motion2 = CMMotionManager()
    var timer: Timer!
    var old_yaw2 = 0.0
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
    
    //MARK: URLSESSION Protocols
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Connected to server")
        self.receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Disconnect from Server \(reason)")
    }
}
