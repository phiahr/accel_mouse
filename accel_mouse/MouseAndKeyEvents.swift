//
//  MouseAndKeyEvents.swift
//  accel_mouse
//
//  Created by Philipp Ahrendt on 04.10.22.
//

import Foundation
import AVFAudio

extension NetworkManager
{
    func sendLeftMouseClick()
    {
        let leftMouseClick = MouseClick(leftMouseClick: true, rightMouseClick: false, mouseDoubleClick: false, scroll: 0.0)
        
        guard let uploadData = try? JSONEncoder().encode(leftMouseClick) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendRightMouseClick()
    {
        let rightMouseClick = MouseClick(leftMouseClick: false, rightMouseClick: true, mouseDoubleClick: false, scroll: 0.0)
        
        guard let uploadData = try? JSONEncoder().encode(rightMouseClick) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendMouseDoubleClick()
    {
        let mouseDoubleClick = MouseClick(leftMouseClick: false, rightMouseClick: false, mouseDoubleClick: true, scroll: 0.0)
        
        guard let uploadData = try? JSONEncoder().encode(mouseDoubleClick) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendScroll(offset: Double)
    {
        let scrollOffset = MouseClick(leftMouseClick: false, rightMouseClick: false, mouseDoubleClick: false, scroll: offset)
        
        guard let uploadData = try? JSONEncoder().encode(scrollOffset) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendLeftArrow()
    {
        let leftArrow = KeyPress(switchTab: false, switchToLaser: false, missionCtrl: false, leftArrow: true, rightArrow: false)
        
        guard let uploadData = try? JSONEncoder().encode(leftArrow) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendRightArrow()
    {
        let rightArrow = KeyPress(switchTab: false, switchToLaser: false, missionCtrl: false, leftArrow: false, rightArrow: true)
        
        guard let uploadData = try? JSONEncoder().encode(rightArrow) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendSwitchTab()
    {
        let switchTab = KeyPress(switchTab: true, switchToLaser: false, missionCtrl: false, leftArrow: false, rightArrow: false)
        
        guard let uploadData = try? JSONEncoder().encode(switchTab) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendSwitchToLaser()
    {
        let switchToLaser = KeyPress(switchTab: false, switchToLaser: true, missionCtrl: false, leftArrow: false, rightArrow: false)
        
        guard let uploadData = try? JSONEncoder().encode(switchToLaser) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    func sendMissionCtrl()
    {
        let missionCtrl = KeyPress(switchTab: false, switchToLaser: false, missionCtrl: true, leftArrow: false, rightArrow: false)

        guard let uploadData = try? JSONEncoder().encode(missionCtrl) else {
            return
        }
        send(uploadData: uploadData)
    }
    
    //MARK: AudioButtons
    

    func listenVolumeButton(){
         
          let audioSession = AVAudioSession.sharedInstance()
          do {
               try audioSession.setActive(true, options: [])
          audioSession.addObserver(self, forKeyPath: "outputVolume",
                                   options: NSKeyValueObservingOptions.new, context: nil)
               audioLevel = audioSession.outputVolume
          } catch {
               print("Error")
          }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "outputVolume"{
            let audioSession = AVAudioSession.sharedInstance()
            
            if audioSession.outputVolume > audioLevel || audioSession.outputVolume == 1.0 {
                print("send Left MouseClick")
                self.sendLeftMouseClick()
            }
            if audioSession.outputVolume < audioLevel || audioSession.outputVolume == 0.0{
                print("send right MouseClick")
                self.sendLeftMouseClick()
            }
        audioLevel = audioSession.outputVolume
        }
    }
}
