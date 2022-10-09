//
//  ContentView.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 30.09.22.
//

import SwiftUI

struct ContentView: View {
    var nManager = NetworkManager()
    var attitude = AttitudeCalculator()

//    var m = Manager()
    @State private var presentAlert = false
    @State private var ipAddress: String = "172.20.10.2"
    @State private var isConnect = true
    
    @Environment(\.colorScheme) var colorScheme
    
    init(){
    }
    var body: some View {
        VStack{
//            Spacer()
//            Button("Start Motion Updates") {
//                nManager.startMotionUpdates()
//            }
//                .padding()
//            Button("Send Data to Server") {
////                nManager.send(attitude:)
//            }
//                .padding()
            Spacer()
            HStack{
                Spacer()
                Button("Mission Control") {
                    nManager.sendMissionCtrl()
                }
//                    .font(Font.title)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(40)
                    .foregroundColor(Color.white)
                Button("Switch \n tab") {
                    nManager.sendSwitchTab()
                }
//                    .font(Font.title)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(40)
                    .foregroundColor(Color.white)
//                    .padding(10)
                Button("Laser pointer") {
                    nManager.sendSwitchToLaser()
                }
//                    .font(Font.title)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(40)
                    .foregroundColor(Color.white)
//                Spacer()
//                    .padding(10)
            }
            HStack{
                Button(ipAddress) {
                            presentAlert = true
                        }
                        .alert("Settings", isPresented: $presentAlert, actions: {
                            TextField("IP Address", text: $ipAddress)
                            
                            Button("Save", action: {
                                print("IP address:", ipAddress)
                                nManager.ipAddress = ipAddress
                                
                            })
                            Button("Cancel", role: .cancel, action: {})
                        }, message: {
                            Text("Please enter your ip address.")
                        })
                        .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 0))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                //                Spacer()
            
                if isConnect {
                    Button("Connect") {
                        nManager.connect()
                        isConnect.toggle()
                    }
                        .frame(maxWidth: .infinity)
                        .font(Font.title)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(40)
                        .foregroundColor(Color.white)
                        .padding(10)
//                        .overlay(
//                           RoundedRectangle(cornerRadius: 40)
//                               .stroke(Color.blue, lineWidth: 5)
//                        )
                }
                else {
                    Button("Disconnect") {
                        nManager.disconnect()
                        isConnect.toggle()
                    }
                    .frame(maxWidth: .infinity)
                    .font(Font.title)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(40)
                    .foregroundColor(Color.white)
                    .padding(10)
                }
                
            }
            
            
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            print("Double tapped!")
            nManager.sendMouseDoubleClick()
        }
        .onTapGesture {
            print("Left Mouse click")
            nManager.sendLeftMouseClick()
        }
        .onLongPressGesture {
            print("Long press -> right click")
            nManager.sendRightMouseClick()
        }
        
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
