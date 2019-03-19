//
//  AudioPlayerController+Observab.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation
import AVFoundation
import FreeStreamer


// MARK: - Observer
extension AudioPlayerController {
    
    
    /// MARK - 添加观察者
    internal func addObserver() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioStreamStateDidChange(_:)),
                                               name: NSNotification.Name.FSAudioStreamStateChange,
                                               object: nil)
    }
    
    
    /// MARK - 音频流状态变化
    @objc private func audioStreamStateDidChange(_ notification: Notification) {
        
        guard let object = notification.object as? FSAudioStream,
            object == audioStream,
            let userInfo = notification.userInfo,
            let stateInt = userInfo[FSAudioStreamNotificationKey_State] as? Int,
            let state = FSAudioStreamState(rawValue: stateInt) else {
                return
        }
        
        if state == .fsAudioStreamRetrievingURL {
            
            playerState = .loading
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
        } else if state == .fsAudioStreamBuffering {
            
            songSwitchInProgress = false
            if automaticAudioSessionHandlingEnabled {
                setCategory(AVAudioSession.Category.playback)
            }
            setActive(true)
            
            bufferState = .buffering
            playerState = .buffering
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            
        } else if state == .fsAudioStreamSeeking {
            return
        } else if state == .fsAudioStreamPlaying {
            
            let totalTime = audioStream.duration.playbackTimeInSeconds * 1000
            delegate?.audioController(self, totalTime: TimeInterval(totalTime))
            if playerState != .playing {
                // 播放进度以及时间进度定时器启用
                startPlayerTimer()
                playerState = .playing
                delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            }
            
        } else if state == .fsAudioStreamPaused {
            
            playerState = .paused
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            //暂停的话,播放进度以及时间进度定时器停用
            stopPlayerTimer()
        } else if state == .fsAudioStreamStopped && !songSwitchInProgress {
            
            debugPrint("没有下一个播放列表项。音频才会停止")
            playerState = .stopped
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            //歌曲全部播放完成的话
            stopPlayerTimer()
            setActive(false)
        } else if state == .fsAudioStreamPlaybackCompleted && (hasNextItem() || playerMode == .one) {
            currentPlaylistItemIndex = calculatePlayer(playerMode, true)
            songSwitchInProgress = true
            playerState = .switchSong
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            play()
        } else if state == .fsAudioStreamFailed {
            playerState = .error
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            setActive(false)
        } else if state == .fsAudioStreamEndOfFile {
            
            // 定时器停止后需要再次调用获取进度方法，防止出现进度不准确的情况
            updateBuffer()
            stopBufferTimer()
            
            
            ///判断是否预加载下一个
            let proxy = streams[calculatePlayer(playerMode, true)]
            
            guard let temUrl = proxy.url,
                temUrl.absoluteString != audioStream.url.absoluteString,
                preloadNextPlaylistItemAutomatically == true else {
                    return
            }
            
            /// 判断是否有下一个，如果有的话，进入提前预加载
            if hasNextItem() {
                
                let nextStream = proxy.audioStream
                
                if let temDelegate = delegate {
                    if temDelegate.audioController(self, allowPreloadingFor: nextStream) {
                        nextStream.preload()
                    }
                } else {
                    nextStream.preload()
                }
                delegate?.audioController(self, preloadStartedFor: nextStream)
            }
        }
    }
}
