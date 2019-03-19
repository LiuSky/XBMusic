//
//  AudioPlayerController+RouteChangeNotification.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation
import AVFoundation


// MARK: - Add Nocation
extension AudioPlayerController {
    
    /// 添加中断通知和线路改变通知
    internal func addInterruptionAndRouteChangeNotification() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.interruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.routeChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    
    /// 中断通知事件(一般指的是电话接入,或者其他App播放音视频等)
    @objc private func interruption(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
            let typeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeRawValue) else {
                return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            
            guard let optionRawValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt,
                AVAudioSession.InterruptionOptions(rawValue: optionRawValue) == .shouldResume else {
                    return
            }
            play()
        }
    }
    
    
    /// 线路改变事件(一般指的是耳机的插入拔出)
    @objc private func routeChange(notification: NSNotification) {
        
        guard let userInfo = notification.userInfo,
            let typeRawValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let type = AVAudioSession.RouteChangeReason(rawValue: typeRawValue) else {
                return
        }
        
        
        if type == .oldDeviceUnavailable {
            
            guard let routeDescription = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription,
                let portDescription = routeDescription.outputs.first else {
                    return
            }
            
            /// 原设备为耳机则暂停
            if portDescription.portType == .headphones {
                stop()
            }
        }
    }
}
