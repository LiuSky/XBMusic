//
//  AudioPlayerControllerDelegate.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/13.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import Foundation
import FreeStreamer


/// MARK - AudioPlayerControllerDelegate
public protocol AudioPlayerControllerDelegate: NSObjectProtocol {
    
    /// 播放器状态改变
    ///
    /// - Parameters:
    ///   - audioController: audioController
    ///   - state: AudioPlayerState
    ///   - resources: AudioResources
    /// - Returns: return value description
    func audioController(_ audioController: AudioPlayerController, statusChanged state: AudioPlayerState, resources: AudioResources?)
    

    /// 播放时间（单位：毫秒)、总时间（单位：毫秒）、进度（播放时间 / 总时间）
    ///
    /// - Parameters:
    ///   - audioController: audioController
    ///   - currentTime: currentTime
    ///   - totalTime: totalTime
    ///   - progress: progress
    /// - Returns: return value description
    func audioController(_ audioController: AudioPlayerController, currentTime: TimeInterval, progress: Float)

    
    /// 总时间（单位：毫秒）
    ///
    /// - Parameters:
    ///   - audioController: audioController
    ///   - totalTime: totalTime
    /// - Returns: return value description
    func audioController(_ audioController: AudioPlayerController, totalTime: TimeInterval)
    
    
    /// 缓冲进度
    ///
    /// - Parameters:
    ///   - audioController: audioController
    ///   - bufferProgress: bufferProgress
    /// - Returns: return value description
    func audioController(_ audioController: AudioPlayerController, bufferProgress: Float)
    
    
    /// 允许预加载流
    ///
    /// - Parameters:
    ///   - audioController: AudioPlayerController
    ///   - stream: stream
    /// - Returns: Bool
    func audioController(_ audioController: AudioPlayerController, allowPreloadingFor stream: FSAudioStream) -> Bool
    
    
    /// 预加载的开始
    ///
    /// - Parameters:
    ///   - audioController: AudioPlayerController
    ///   - stream: stream
    func audioController(_ audioController: AudioPlayerController, preloadStartedFor stream: FSAudioStream)
}



// MARK: - AudioPlayerControllerDelegate
extension AudioPlayerControllerDelegate {
    
    func audioController(_ audioController: AudioPlayerController, statusChanged state: AudioPlayerState) {}
    func audioController(_ audioController: AudioPlayerController, currentTime: TimeInterval, progress: Float) {}
    func audioController(_ audioController: AudioPlayerController, totalTime: TimeInterval) {}
    func audioController(_ audioController: AudioPlayerController, bufferProgress: Float) {}
    func audioController(_ audioController: AudioPlayerController, allowPreloadingFor stream: FSAudioStream) -> Bool {
        return true
    }
    func audioController(_ audioController: AudioPlayerController, preloadStartedFor stream: FSAudioStream) {}
}

