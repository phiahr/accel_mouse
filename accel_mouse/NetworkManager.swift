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
    let frequency = 0.2 // 0.1
    private var webSocket : URLSessionWebSocketTask!

    var mouseTap = false
    
    override init(){
        super.init()
        
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
        startMotionUpdates()
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
        print("Send Data to Server")
        
        let workItem = DispatchWorkItem{
        
            self.webSocket?.send(URLSessionWebSocketTask.Message.data(uploadData), completionHandler: { error in
//        self.webSocket?.send(URLSessionWebSocketTask.Message.string("Hello"), completionHandler: { error in
           
           if error == nil {
               // if error is nil we will continue to send messages else we will stop
//               self.sendDataToServer()
           }else{
               print(error)
           }
        })
        }

        DispatchQueue.global().asyncAfter(deadline: .now(), execute: workItem)
    }
    
    func sendLeftMouseClick()
    {
        let leftMouseClick = MouseClick(leftMouseClick: true, rightMouseClick: false)
        
        guard let uploadData = try? JSONEncoder().encode(leftMouseClick) else {
            return
        }
        send(uploadData: uploadData)
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
    }
    
    func handleMotionUpdates()
    {
        
        manager.deviceMotionUpdateInterval = frequency
        print("Handle motion updates")
        
        var old_vel_x = 0.0
        var old_dist_x = 0.0
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

            // Get attitude orientation
            let pitch = motion?.attitude.pitch
            let roll = motion?.attitude.roll
            let yaw = motion?.attitude.yaw

            // Get gravity vector
            let g_x = motion?.gravity.x
            let g_y = motion?.gravity.y
            let g_z = motion?.gravity.z
            
            var vel_x = old_vel_x + a_x! * self.frequency
            var dist_x = old_dist_x + vel_x * self.frequency
//            print("pitch: ", pitch!, "roll: ", roll!, "yaw: ", yaw!)
//            print("yaw: ", (yaw! * 180 / .pi))
            print(a_x)
            
            old_vel_x = vel_x
            old_dist_x = dist_x
            let attitude = Attitude(attitude: motion!.attitude)
            guard let data = try? JSONEncoder().encode(attitude) else {
                return
            }
            //self.send(uploadData: data)
        }
    }
    
    let motion2 = CMMotionManager()
    var timer: Timer!
    var old_yaw = 0.0
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion2.isAccelerometerAvailable {
           self.motion2.accelerometerUpdateInterval = frequency  // 60 Hz
          self.motion2.startAccelerometerUpdates()

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
                 print("estimated roll: ", estimated_roll*180 / .pi)
             // Use the accelerometer data in your app.
             }
          })

          // Add the timer to the current run loop.
           RunLoop.current.add(self.timer, forMode: .default)
       }
    }
    
    
    // Yaw is biased from starting position??
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
                 let y = data.rotationRate.y
                 let z = data.rotationRate.z
                  let estimated_yaw = self.old_yaw + (-z) * self.frequency
                  self.old_yaw = estimated_yaw
                  print("estimated yaw: ", estimated_yaw*180 / .pi)
              // Use the accelerometer data in your app.
              }
           })

           // Add the timer to the current run loop.
            RunLoop.current.add(self.timer, forMode: .default)
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


// Example for Reference attitude to start from
//-(void) startPitch {
//    // referenceAttitude is a property
//    self.referenceAttitude = self.motionManager.deviceMotion.attitude;
//}
//- (void)drawView {
//    CMAttitude *currentAttitude = self.motionManager.deviceMotion.attitude;
//    [currentAttitude multiplyByInverseOfAttitude: self.referenceAttitude];
//    // Render bat using currentAttitude
//    [self updateModelsWithAttitude:currentAttitude];
//    [renderer render];
//}
