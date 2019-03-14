//
//  AudioStreamProxy.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/13.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation
import FreeStreamer


/// MARK - 音频流代理
final class AudioStreamProxy: NSObject {
    
    /// MARK - public
    /// 地址
    public var url: URL?
    
    /// MARK - private
    /// 音频流
    private(set) lazy var audioStream: FSAudioStream = {
        
        let config: FSStreamConfiguration = FSStreamConfiguration()
        
        //禁用音频流的音频会话处理;音频控制器处理它
        config.automaticAudioSessionHandlingEnabled = false
        config.cacheDirectory = self.audioController?.cacheDirectory
        config.cacheEnabled = self.audioController?.currentPlaylistItem?.cacheEnabled ?? false
        let temAudioStream = FSAudioStream(configuration: config)!
        if self.audioController?.needToSetVolume ?? false,
            let outputVolume = self.audioController?.outputVolume {
            temAudioStream.volume = outputVolume
        }
        
        if let temUrl = self.url {
            temAudioStream.url = temUrl as NSURL
        }
        
        return temAudioStream
    }()
    
    /// 音频控制器
    private(set) weak var audioController: AudioPlayerController?
    
    /// 初始化
    public init(audioController: AudioPlayerController) {
        super.init()
        self.audioController = audioController
    }
    
    /// MARK - 禁用
    public func deactivate() {
        self.audioStream.stop()
    }
    
    /// MARK - 释放
    deinit {
        self.deactivate()
    }
}
