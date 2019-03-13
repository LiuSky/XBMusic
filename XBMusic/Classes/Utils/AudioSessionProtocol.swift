//
//  AudioSessionProtocol.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//

import AVFoundation


/// MARK - 会话协议
public protocol AudioSessionProtocol {
    
    /// 设置音频会话分类
    func setCategory(_ category: AVAudioSession.Category)
    
    /// 设置会话是否活动
    func setActive(_ active: Bool)
}


// MARK: - AudioSessionProtocol
extension AudioSessionProtocol {
    
    public func setCategory(_ category: AVAudioSession.Category) {
        
        let sesion = AVAudioSession.sharedInstance()
        if #available(iOS 10.0, *) {
            try? sesion.setCategory(category, mode: .default)
            
        } else {
            // Workaround until https://forums.swift.org/t/using-methods-marked-unavailable-in-swift-4-2/14949 isn't fixed
            sesion.perform(NSSelectorFromString("setCategory:error:"), with: category)
        }
    }
    
    /// 设置会话是否活动
    public func setActive(_ active: Bool) {
        
        try? AVAudioSession.sharedInstance().setActive(active, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
    }
}

