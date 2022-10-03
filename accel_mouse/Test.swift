//
//  Test.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 02.10.22.
//

import Foundation
import CoreMotion

class Manager: NSObject, URLSessionWebSocketDelegate
{

    let motion = CMMotionManager()
    var timer: Timer?

    var webSocket: URLSessionWebSocketTask!
    struct Position: Codable {
        let x: Double
        let y: Double
        let z: Double
        let m_x: Double
        let m_y: Double
        let m_z: Double
        let g_x: Double
        let g_y: Double
        let g_z: Double
    }

    override init() {
        //
        super.init()
        startAccelerometers()

        let url = URL(string: "ws://172.20.10.2:8000/ws")!


        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())

        self.webSocket = session.webSocketTask(with: url)

        webSocket.resume()
    }
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
        if self.motion.isMagnetometerAvailable{
            if self.motion.isGyroAvailable {
                if self.motion.isAccelerometerAvailable {
                    let dt = 1.0 / 60.0 // 60 Hz
                    var s = SIMD3(x: 0.0, y: 0.0, z: 0.0)
                    var u = SIMD3(x: 0.0, y: 0.0, z: 0.0)

                    self.motion.accelerometerUpdateInterval = dt
                    self.motion.magnetometerUpdateInterval = dt
                    self.motion.gyroUpdateInterval = dt

                    self.motion.startAccelerometerUpdates()
                    self.motion.startMagnetometerUpdates()
                    self.motion.startGyroUpdates()

                    // Configure a timer to fetch the data.
                    self.timer = Timer(fire: Date(), interval: (dt),
                                       repeats: true, block: { (timer) in
                        // Get the accelerometer data.
                        if let data = self.motion.accelerometerData {
                            if let mData = self.motion.magnetometerData{
                                if let gData = self.motion.gyroData{

                                    let x = data.acceleration.x
                                    let y = data.acceleration.y
                                    let z = data.acceleration.z

                                    let m_x = mData.magneticField.x
                                    let m_y = mData.magneticField.y
                                    let m_z = mData.magneticField.z

                                    let g_x = gData.rotationRate.x
                                    let g_y = gData.rotationRate.y
                                    let g_z = gData.rotationRate.z
                                    //                 let a = [Double(x),Double(y),Double(z)]
                                    let a = SIMD3(x: x, y: y, z: z)
                                    let position = Position(x: x, y: y, z: z, m_x: m_x, m_y: m_y, m_z: m_z, g_x: g_x, g_y: g_y, g_z: g_z)
                                    //print(x, y, z)
                                    self.send(position: position)
                                    //                 if (abs(x) < 0.01 ||  abs(y) < 0.01)
                                    //                 {
                                    //                    u = SIMD3(x: 0.0, y: 0.0, z: 0.0)
                                    //
                                    //                 }
                                    //                 if (abs(x) > 0.1 ||  abs(y) > 0.1)
                                    //                 {
                                    ////                     print(a)
                                    //                     u = u + a * dt;
                                    //                     s = s + u * dt;
                                    //                     let pos = Position(x: s.x, y: s.y, z: s.z)
                                    ////                      print(pos)
                                    //
                                    //                     //self.uploadData(position: position)
                                    //                 }
                                    print("xSpeed: ", u.x)
                                }
                            }
                            // Use the accelerometer data in your app.
                        }
                    })

                    // Add the timer to the current run loop.
                    RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.default)
                }
            }
        }
    }

//    func uploadData(position: Position)
//    {
//
//
//        // ...
//        guard let uploadData = try? JSONEncoder().encode(position) else {
//            return
//        }
//
//        let url = URL(string: "ws://172.20.10.2:7071/ws")!
//
//
//
////        var request = URLRequest(url: url)
////
////
////        request.httpMethod = "POST"
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////
////
////
////        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
////            if let error = error {
////                print ("error: \(error)")
////                return
////            }
////            print(response)
////            print((response as! HTTPURLResponse).statusCode)
////            guard let response = response as? HTTPURLResponse,
////                (200...299).contains(response.statusCode) else {
////                print ("server error")
////                return
////            }
////            if let mimeType = response.mimeType,
////                mimeType == "application/json",
////                let data = data,
////                let dataString = String(data: data, encoding: .utf8) {
////                print ("got data: \(dataString)")
////            }
////        }
////        task.resume()
//    }
//
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    print("Connected to server")
                self.receive()
//                self.send()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    print("Disconnect from Server \(reason)")
    }


    func receive(){
            /// This Recurring will keep us connected to the server
            /*
             - Create a workItem
             - Add it to the Queue
             */

            let workItem = DispatchWorkItem{ [weak self] in

                self?.webSocket.receive(completionHandler: { result in


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
            DispatchQueue.global().asyncAfter(deadline: .now() + 1 , execute: workItem)

        }

    func send(position: Position){
           /*
            - Create a workItem
            - Add it to the Queue
            */

           let workItem = DispatchWorkItem{

               guard let uploadData = try? JSONEncoder().encode(position) else {
                   return
               }
               self.webSocket.send(URLSessionWebSocketTask.Message.data(uploadData), completionHandler: { error in

//
//                   if error == nil {
//                       // if error is nil we will continue to send messages else we will stop
//                       self.send(position: position)
//                   }else{
//                       print(error)
//                   }
               })
           }

           DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: workItem)
       }

    @objc func closeSession(){
    webSocket.cancel(with: .goingAway, reason: "You've Closed The Connection".data(using: .utf8))
    }

}
