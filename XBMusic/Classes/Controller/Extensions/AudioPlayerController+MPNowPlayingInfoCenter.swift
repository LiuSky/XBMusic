//
//  AudioPlayerController+MPNowPlayingInfoCenter.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import Foundation
import MediaPlayer


// MARK: - 后台播放(锁屏)
extension AudioPlayerController {
    
    /// 注册后台前台通知
    internal func addBackgroundAndForegroundNotification() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    
    /// 进入后台事件
    @objc private func didEnterBackground() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        AudioLockScreenController().createRemoteCommandCenter()
    }
    
    /// 进入前台事件
    @objc private func willEnterForeground() {
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    
    /// 添加锁屏操作通知
    internal func addLockScreenOperationNotification() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioPlayerTaskPlay),
                                               name: Notification.Name.AudioPlayerTask.play, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioPlayerTaskPause),
                                               name: Notification.Name.AudioPlayerTask.pause, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioPlayerTaskPrevious),
                                               name: Notification.Name.AudioPlayerTask.previous, object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioPlayerTaskNext),
                                               name: Notification.Name.AudioPlayerTask.next, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioPlayerTaskChangeProgress(_:)),
                                               name: Notification.Name.AudioPlayerTask.changeProgress, object: nil)
        
    }
    
    /// 锁屏点击播放
    @objc private func audioPlayerTaskPlay() {
        play()
    }
    
    /// 锁屏点击暂停
    @objc private func audioPlayerTaskPause() {
        
        stopPlayerTimer()
        pause()
        ///有几个注意点是，每次你暂停时需要保存当前的音乐播放进度和锁屏下进度光标的速度设置为接近0的数（0.00001），以便下次恢复播放时锁屏下进度光标位置能正常
        var info: [String: Any] = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 0.0)//进度光标的速度
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: audioStream.currentTimePlayed.playbackTimeInSeconds)//当前已经播放时间
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        
    }
    
    /// 上一首
    @objc private func audioPlayerTaskPrevious() {
        playPreviousItem()
    }
    
    /// 下一首
    @objc private func audioPlayerTaskNext() {
        playNextItem()
    }
    
    
    /// 进度通知
    ///
    /// - Parameter noti: <#noti description#>
    @objc private func audioPlayerTaskChangeProgress(_ noti: Notification) {
        
        guard let positionTime = noti.object as? Double else {
            return
        }
        
        setPlayerProgress(Float(positionTime) / audioStream.duration.playbackTimeInSeconds)
    }
    
    /// 刷新锁屏控制器
    internal func updatePlayingInfoCenter() {
        
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = "测试而已"//歌曲名设置
        info[MPMediaItemPropertyArtist] = "啊嘴"//歌手名设置
        //info[MPMediaItemPropertyArtwork] = //专辑图片设置
        info[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: audioStream.duration.playbackTimeInSeconds)//歌曲总时间设置
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: audioStream.currentTimePlayed.playbackTimeInSeconds)//当前已经播放时间
        info[MPNowPlayingInfoPropertyPlaybackRate] = NSNumber(value: 1.0)//进度光标的速度
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
