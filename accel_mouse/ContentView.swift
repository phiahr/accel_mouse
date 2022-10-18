//
//  ContentView.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 30.09.22.
//

import SwiftUI

struct ContentView: View {
    var nManager = NetworkManager()
//    var attitude = AttitudeCalculator()

//    var m = Manager()
    @State private var presentAlert = false
    @State private var ipAddress: String = "172.20.10.2"
    @State private var isConnect = true
    @State private var offset = CGSize.zero
    @State private var useEstimatedValues = false
    
    @Environment(\.colorScheme) var colorScheme
    
    init(){
    }
    var body: some View {
        VStack{

            HStack{
                Spacer()
                Image(systemName: "airtag.fill")
                    .resizable()
                    .frame(width: 42.0, height: 42.0)
                    .foregroundColor(useEstimatedValues ?  Color.gray : Color.black)
                    .padding()
                    .onTapGesture(perform: {
                        nManager.useEstimatedValues.toggle()
                        useEstimatedValues.toggle()
                    })
            }
            Spacer()
            HStack{
                Button {
                    print("left arrow")
                    nManager.sendLeftArrow()
                } label: {
                    Image(systemName: "arrow.left.square.fill")
                        .resizable()
                        .frame(width: 150.0, height: 75.0)
                        .foregroundColor(Color.mint)
                        .padding()
                }
                Button {
                    print("right arrow")
                    nManager.sendRightArrow()
                } label: {
                    Image(systemName: "arrow.right.square.fill")
                        .resizable()
                        .frame(width: 150.0, height: 75.0)
                        .foregroundColor(Color.mint)
                        .padding()
                }
            }
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
        .gesture(
            DragGesture()
            .onChanged({ gesture in
                offset = gesture.translation
            })
            .onEnded { _ in
                print("offset: ", offset)
                nManager.sendScroll(offset: offset.height)
                }
        )
        
    }
    
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
