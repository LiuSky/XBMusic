//
//  AudioPlayerState.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation


/// MARK - 音频播放状态
public enum AudioPlayerState: Int {

    /// 空
    case none
    
    ///  加载中
    case loading

    ///  缓冲中
    case buffering

    ///  播放
    case playing

    ///  暂停
    case paused
    
    ///  切换
    case switchSong

    ///  停止
    case stopped

    ///  错误
    case error
}


// MARK: - CustomStringConvertible
extension AudioPlayerState: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .none:
            return "空"
        case .loading:
            return "加载中"
        case .buffering:
            return "缓冲中"
        case .playing:
            return "播放"
        case .paused:
            return "暂停（播放器主动发出或被其他播放打断）"
        case .switchSong:
            return "切换"
        case .stopped:
            return "停止"
        case .error:
            return "错误"
        }
    }
}


