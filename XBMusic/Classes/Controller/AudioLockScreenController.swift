//
//  AudioLockScreenController.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/15.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import Foundation
import MediaPlayer
import AVFoundation

// MARK: - 音乐通知任务
public extension Notification.Name {
    
    struct AudioPlayerTask {
        
        /// 上一首通知
        public static let previous = Notification.Name("com.xb.audio.notification.name.previous")
        
        /// 下一首通知
        public static let next = Notification.Name("com.xb.audio.notification.name.next")
        
        /// 喜欢
        public static let like = Notification.Name("com.xb.audio.notification.name.like")
        
        /// 暂停
        public static let pause = Notification.Name("com.xb.audio.notification.name.pause")
        
        /// 播放
        public static let play = Notification.Name("com.xb.audio.notification.name.play")
        
        /// 改变播放进度
        public static let changeProgress = Notification.Name("com.xb.audio.notification.name.changeProgress")
        
        /// 快进
        public static let skipBackwardCommand = Notification.Name("com.xb.audio.notification.name.skipBackwardCommand")
        
        /// 快退
        public static let skipForwardCommand = Notification.Name("com.xb.audio.notification.name.skipForwardCommand")
    }
}




/// MARK - 音频锁屏界面控制器
public class AudioLockScreenController: AudioSessionProtocol {
    
    /// MARK - 创建锁屏中心
    public func createRemoteCommandCenter() {
        
        //MPFeedbackCommand对象反映了当前App所播放的反馈状态. MPRemoteCommandCenter对象提供feedback对象用于对媒体文件进行喜欢, 不喜欢, 标记的操作. 效果类似于网易云音乐锁屏时的效果
        let commandCenter = MPRemoteCommandCenter.shared()
        
//        // 添加喜欢按钮
//        let likeCommand = commandCenter.likeCommand
//        likeCommand.isEnabled = true
//        likeCommand.localizedTitle = "喜欢"
//        likeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.like, object: nil)
//            return MPRemoteCommandHandlerStatus.success
//        }
        
        
        // 添加不喜欢按钮,假装是"上一首"
//        let dislikeCommand = commandCenter.dislikeCommand
//        dislikeCommand.isEnabled = true
//        dislikeCommand.localizedTitle = "上一首"
//        dislikeCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
//            NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.previous, object: nil)
//            return MPRemoteCommandHandlerStatus.success
//        }

        
        //commandCenter.togglePlayPauseCommand 耳机线控的暂停/播放
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.pause, object: nil)
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.play, object: nil)
            return MPRemoteCommandHandlerStatus.success
        }
        
        
        commandCenter.previousTrackCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.previous, object: nil)
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.nextTrackCommand.addTarget { (eventFor) -> MPRemoteCommandHandlerStatus in
            NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.next, object: nil)
            return MPRemoteCommandHandlerStatus.success
        }
        
        
        // 在控制台拖动进度条调节进度
        if #available(iOS 9.1, *) {
            commandCenter.changePlaybackPositionCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
                
                guard let playbackPositionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                    return MPRemoteCommandHandlerStatus.success
                }
                NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.changeProgress, object: playbackPositionEvent.positionTime)
                
                return MPRemoteCommandHandlerStatus.success
            }
        } else {
            
            /*
             这边可以设置快进以及快退(一般不去设置原因有两点:)
             1.左边提供给更多选项功能
             2.提供给下一首功能
             */
            
            
            /// 快退
            let skipForward: (_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus = { event in
                
                guard let command = event.command as? MPSkipIntervalCommand else {
                    return MPRemoteCommandHandlerStatus.noSuchContent
                }
                
                let interval = command.preferredIntervals[0]
                NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.skipForwardCommand, object: interval)
                return MPRemoteCommandHandlerStatus.success
            }
            
            /// 快退命令(每次快退30秒)
            let skipForwardCommand = commandCenter.skipForwardCommand
            skipForwardCommand.isEnabled = true
            skipForwardCommand.addTarget(handler: skipForward)
            skipForwardCommand.preferredIntervals = [30]
            
            
            
            /// 快进
            let skipBackward: (_ event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus = { event in
                
                guard let command = event.command as? MPSkipIntervalCommand else {
                    return MPRemoteCommandHandlerStatus.noSuchContent
                }
                
                let interval = command.preferredIntervals[0]
                NotificationCenter.default.post(name: NSNotification.Name.AudioPlayerTask.skipBackwardCommand, object: interval)
                return MPRemoteCommandHandlerStatus.success
            }
            
            
            /// 快进命令(每次快退30秒)
            let skipBackwardCommand = commandCenter.skipBackwardCommand
            skipBackwardCommand.isEnabled = true
            skipBackwardCommand.addTarget(handler: skipBackward)
            skipBackwardCommand.preferredIntervals = [30]
        }
    }
    
    /// 移除远程控制中心
    public func removeRemoteCommandCenter() {
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.likeCommand.removeTarget(self)
        commandCenter.dislikeCommand.removeTarget(self)
        commandCenter.bookmarkCommand.removeTarget(self)
        commandCenter.nextTrackCommand.removeTarget(self)
        commandCenter.skipBackwardCommand.removeTarget(self)
        commandCenter.skipForwardCommand.removeTarget(self)
        if #available(iOS 9.1, *) {
            commandCenter.changePlaybackPositionCommand.removeTarget(self)
        }
    }
}
