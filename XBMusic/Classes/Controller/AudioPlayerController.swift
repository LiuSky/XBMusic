//
//  AudioPlayerController.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation
import AVFoundation
import FreeStreamer


/// MARK - 音频播放控制器
public class AudioPlayerController: NSObject, AudioSessionProtocol {
    
    /// MARK - public
    /// 是否启用自动音频会话处理
    public var automaticAudioSessionHandlingEnabled: Bool = true
    
    /// 是否预加载下一个播放列表项
    public var preloadNextPlaylistItemAutomatically: Bool = true
    
    /// MARK - private
    /// 配置
    private(set) lazy var configuration: FSStreamConfiguration = FSStreamConfiguration()
    
    /// 当前播放列表索引
    private var currentPlaylistItemIndex: Int = 0
    
    /// 音频流代理数组
    private lazy var streams: [AudioStreamProxy] = []
    
    /// 播放列表数组
    private(set) lazy var playlistItems: [AudioResources] = []
    
    /// 需要设置音量(默认为false)
    private(set) var needToSetVolume: Bool = false
    
    /// 准备播放
    private var readyToPlay: Bool = false
    
    /// 正在进行歌曲切换
    private var songSwitchInProgress: Bool = false
    
    /// 输出音量(默认1)
    private(set) var outputVolume: Float = 1.0
    
    /// 初始化
    public override init() {
        super.init()
        self.addObserver()
    }
    
    /// 初始化音频资源
    ///
    /// - Parameter resources: AudioResources
    public convenience init(with resource: AudioResources) {
        self.init()
        playlistItems.append(resource)
        assignmentStreams()
    }
    
    
    /// 初始化音频资源列表
    ///
    /// - Parameter resources: <#resources description#>
    public convenience init(with resources: [AudioResources]) {
        self.init()
        playlistItems.append(contentsOf: resources)
        assignmentStreams()
    }
    
    
    /// MARK - 释放
    deinit {
        self.removeObserver()
        self.streams.forEach { $0.deactivate() }
        self.setActive(false)
    }
}


// MARK: - Observer
extension AudioPlayerController {
    
    
    /// MARK - 添加观察者
    private func addObserver() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.audioStreamStateDidChange(_:)),
                                               name: NSNotification.Name.FSAudioStreamStateChange,
                                               object: nil)
    }
    
    
    /// MARK - 移除观察者
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// MARK - 音频流状态变化
    @objc private func audioStreamStateDidChange(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let stateInt = userInfo[FSAudioStreamNotificationKey_State] as? Int,
              let state = FSAudioStreamState(rawValue: stateInt) else {
                return
        }
        
        
        if state == .fsAudioStreamRetrievingURL {
            //do thing
            debugPrint("检索url")
        } else if state == .fsAudioStreamEndOfFile {
            
            debugPrint("缓冲完成")
            /// 判断是否预加载下一个
            if !self.preloadNextPlaylistItemAutomatically {
                return
            }
            
            /// 判断是否有下一个，如果有的话，进入提前预加载
            if self.hasNextItem() {
                
                let proxy = self.streams[currentPlaylistItemIndex + 1]
                let nextStream = proxy.audioStream
                
                /// 这边记住做成回调判断当前这个需要不需要预加载
                nextStream.preload()
            }
        } else if state == .fsAudioStreamStopped && !self.songSwitchInProgress {
            
            debugPrint("没有下一个播放列表项。音频才会停止")
            //self.setAudioSessionActive(false)
            
        } else if state == .fsAudioStreamPlaybackCompleted && self.hasNextItem() {
            debugPrint("播放完成")
            self.currentPlaylistItemIndex = self.currentPlaylistItemIndex + 1
            self.songSwitchInProgress = true
            self.play()
        } else if state == .fsAudioStreamFailed {
            debugPrint("加载流失败")
            //self.setAudioSessionActive(false)
        } else if state == .fsAudioStreamBuffering {
            debugPrint("缓冲中")
            self.songSwitchInProgress = false
            
            if self.automaticAudioSessionHandlingEnabled {
                
                if #available(iOS 10.0, *) {
                    try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                } else {
                    // Workaround until https://forums.swift.org/t/using-methods-marked-unavailable-in-swift-4-2/14949 isn't fixed
                    AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
                }
            }
            //self.setAudioSessionActive(true)
        } else if state == .fsAudioStreamPlaying {
            debugPrint("播放中........")
        }
    }
}


// MARK: - private
extension AudioPlayerController {
    
    /// MARK - 获取当前播放的项
    private var currentPlaylistItem: AudioResources? {
        
        if readyToPlay {
            if playlistItems.count > 0 {
                let playlistItem = playlistItems[currentPlaylistItemIndex]
                return playlistItem
            } else {
                return nil
            }
        }
        return nil
    }
    
    
    /// MARK - 当前播放音频
    private var audioStream: FSAudioStream {
        
        let stream: FSAudioStream
        if streams.count == 0 {
            let proxy = AudioStreamProxy(audioController: self)
            streams.append(proxy)
        }
        
        let proxy = streams[currentPlaylistItemIndex]
        stream = proxy.audioStream
        return stream
    }
    
    
    /// MARK - 赋值音频代理对象
    private func assignmentStreams() {
        
        streams = playlistItems.map { model -> AudioStreamProxy in
            let proxy = AudioStreamProxy(audioController: self)
            proxy.url = model.audioUrl
            return proxy
        }
    }
    
    /// MARK - 停用未激活的音频
    private func deactivateInactivateStreams(_ currentActiveStream: Int) {
        
        for (index, item) in streams.enumerated() {
            if index != currentActiveStream {
                item.deactivate()
            }
        }
    }
}




// MARK: - AudioPlayerProtocol
extension AudioPlayerController: AudioPlayerProtocol {
    
    /// MARK - 播放资源
    public func play(from resources: AudioResources) {
        
        play(fromPlaylist: [resources], itemIndex: 0)
    }
    
    /// MARK - 播放列表
    public func play(fromPlaylist playlist: [AudioResources]) {
        play(fromPlaylist: playlist, itemIndex: 0)
    }
    
    /// MARK - 播放列表索引开始
    public func play(fromPlaylist playlist: [AudioResources], itemIndex index: Int) {
        
        stop()
        playlistItems.removeAll()
        streams.removeAll()
        currentPlaylistItemIndex = 0
        playlistItems.append(contentsOf: playlist)
        assignmentStreams()
        playItem(at: index)
    }
    
    /// MARK - 在指定的索引处播放播放列表项
    public func playItem(at index: Int) {
        
        let count = countOfItems()
        guard count != 0,
              index < count else {
            return
        }
        
        audioStream.stop()
        currentPlaylistItemIndex = index
        readyToPlay = true
        deactivateInactivateStreams(index)
        play()
        
    }
    
    /// MARK - 返回播放列表项的数量
    public func countOfItems() -> Int {
        return playlistItems.count
    }
    
    /// MARK - 添加一个项目到播放列表
    public func addItem(_ item: AudioResources) {
        
        playlistItems.append(item)
        let proxy = AudioStreamProxy(audioController: self)
        proxy.url = item.audioUrl
        streams.append(proxy)
        
    }
    
    /// MARK - 将一个项目添加到特定位置的播放列表中
    public func insertItem(_ newItem: AudioResources, at index: Int) {
        
        guard index < playlistItems.count else {
            return
        }
        
        if playlistItems.count == 0 && index == 0 {
            addItem(newItem)
            return
        }
        
        playlistItems.insert(newItem, at: index)
        let proxy = AudioStreamProxy(audioController: self)
        proxy.url = newItem.audioUrl
        streams.insert(proxy, at: index)
        
        if index <= currentPlaylistItemIndex {
            currentPlaylistItemIndex += 1
        }
    }
    
    /// MARK - 将已在播放列表中的项目移动到播放列表中的不同位置
    public func moveItem(at from: Int, _ to: Int) {
        
        let count = countOfItems()
        if count == 0 {
            return
        }
        
        if from >= count || to >= count {
            return
        }
        
        if from == currentPlaylistItemIndex {
            currentPlaylistItemIndex = to
        } else if from < currentPlaylistItemIndex && to > currentPlaylistItemIndex {
            currentPlaylistItemIndex -= 1
        } else if from > currentPlaylistItemIndex && to <= currentPlaylistItemIndex {
            currentPlaylistItemIndex += 1
        }
        
        let audioResources = playlistItems[from]
        playlistItems.remove(at: from)
        playlistItems.insert(audioResources, at: to)
        
        let audioStreamProxy = streams[from]
        streams.remove(at: from)
        streams.insert(audioStreamProxy, at: to)
    }
    
    /// MARK - 替换播放列表项
    public func replaceItem(at index: Int, with item: AudioResources) {
        
        let count = countOfItems()
        guard count != 0,
              index < count else {
            return
        }
        
        // 如果物品当前正在播放，不允许更换
        if currentPlaylistItemIndex == index {
            return
        }
        
        playlistItems[index] = item
        
        let proxy = AudioStreamProxy(audioController: self)
        proxy.url = item.audioUrl
        streams[index] = proxy
    }
    
    /// MARK - 删除播放列表项
    public func removeItem(at index: Int) {
        
        let count = countOfItems()
        guard count != 0,
              index < count else {
                return
        }
        
        if currentPlaylistItemIndex == index && isPlaying() {
            // 当前正在播放，不允许移除
            return
        }
        
        let current = currentPlaylistItem
        self.playlistItems.remove(at: index)
        self.streams.remove(at: index)
        
        
        // 删除后更新当前播放列表项以使其正确
        for (index, item) in playlistItems.enumerated() {
            if item.audioUrl.absoluteString == current?.audioUrl.absoluteString {
                currentPlaylistItemIndex = index
            }
        }
    }
    
    /// MARK - 播放
    public func play() {
        audioStream.play()
    }
    
    /// MARK - 停止播放
    public func stop() {
        
        if streams.count > 0 {
            audioStream.stop()
        }
    }
    
    /// MARK - 暂停
    public func pause() {
        audioStream.pause()
    }
    
    /// MARK - 恢复
    public func resume() {
        audioStream.pause()
    }
    
    /// MARK - 是否正在播放
    public func isPlaying() -> Bool {
        return audioStream.isPlaying()
    }
    
    /// MARK - 是否有多个播放列表项
    public func hasMultiplePlaylistItems() -> Bool {
        return playlistItems.count > 1
    }
    
    /// MARK - 是否有下一个
    public func hasNextItem() -> Bool {
        
        /// 这边注意模式播放方式(后续添加)
        return hasMultiplePlaylistItems() &&
            currentPlaylistItemIndex + 1 < playlistItems.count
    }
    
    /// MARK - 是否有上一个
    public func hasPreviousItem() -> Bool {
        
        /// 这边注意模式播放方式(后续添加)
        return hasMultiplePlaylistItems() &&
               currentPlaylistItemIndex != 0
    }
    
    /// MARK - 播放下一个
    public func playNextItem() {
        
        /// 这边注意模式播放方式(后续添加)
        if self.hasNextItem() {
            self.songSwitchInProgress = true
            self.audioStream.stop()
            self.deactivateInactivateStreams(self.currentPlaylistItemIndex)
            self.currentPlaylistItemIndex = self.currentPlaylistItemIndex + 1
            self.play()
        }
    }
    
    /// MARK - 播放上一个
    public func playPreviousItem() {
        
        /// 这边注意模式播放方式(后续添加)
        if self.hasPreviousItem() {
            self.songSwitchInProgress = true
            self.audioStream.stop()
            self.deactivateInactivateStreams(self.currentPlaylistItemIndex)
            self.currentPlaylistItemIndex = self.currentPlaylistItemIndex - 1
            self.play()
        }
    }
    
    /// MARK - 从某个进度开始播放
    public func setPlayerProgress(_ progress: Float) {
        
        var temProgress: Float = progress
        if progress == 0 { temProgress = 0.001 }
        if progress == 1 { temProgress = 0.999 }
        
        var position = FSStreamPosition(minute: 0,
                                        second: 0,
                                        playbackTimeInSeconds: 0,
                                        position: 0)
        position.position = temProgress
        self.audioStream.seek(to: position)
    }
    
    /// MARK - 设置播放速率 0.5 - 2.0， 1.0是正常速率
    public func setPlayerPlayRate(_ playRate: Float) {
        
        var temPlayRate: Float = 1.0
        if playRate < 0.5 { temPlayRate = 0.5 }
        if playRate > 2.0 { temPlayRate = 2.0 }
        self.audioStream.setPlayRate(temPlayRate)
    }
}