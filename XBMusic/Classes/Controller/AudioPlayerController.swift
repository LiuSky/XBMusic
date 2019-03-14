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
    /// 委托
    public weak var delegate: AudioPlayerControllerDelegate?
    
    /// 是否启用自动音频会话处理
    public var automaticAudioSessionHandlingEnabled: Bool = true
    
    /// 是否预加载下一个播放列表项
    public var preloadNextPlaylistItemAutomatically: Bool = true
    
    /// 缓存路径(默认路径DocumentDirectory)
    public var cacheDirectory: String!
    
    /// MARK - private
    /// 当前播放列表索引
    private var currentPlaylistItemIndex: Int = 0
    
    /// 音频流代理数组
    private lazy var streams: [AudioStreamProxy] = []
    
    /// 播放列表数组
    private(set) lazy var playlistItems: [AudioResources] = []
    
    /// 需要设置音量(默认为false)
    private(set) var needToSetVolume: Bool = false
    
    /// 正在进行歌曲切换
    private var songSwitchInProgress: Bool = false
    
    /// 输出音量(默认1)
    private(set) var outputVolume: Float = 1.0
    
    /// 播放时间进度定时器
    private var playTimer: Timer?
    
    /// 缓冲状态定时器
    private var bufferTimer: Timer?
    
    /// 播放状态
    private(set) var playerState: AudioPlayerState = .none
    
    /// 缓冲状态
    private(set) var bufferState: AudioBufferState = .none
    
    /// 初始化
    public override init() {
        super.init()
        
       let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if paths.count > 0 {
            cacheDirectory = paths[0]
        }
        
        addObserver()
        addInterruptionAndRouteChangeNotification()
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
        
        removeObserver()
        removeNotification()
        streams.forEach { $0.deactivate() }
        setActive(false)
        stopPlayerTimer()
        stopBufferTimer()
        debugPrint("释放音频播放控制器")
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
            
            let totalTime = self.audioStream.duration.playbackTimeInSeconds * 1000
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
            playerState = .ended
            delegate?.audioController(self, statusChanged: playerState, resources: currentPlaylistItem)
            //歌曲全部播放完成的话
            stopPlayerTimer()
            setActive(false)
        } else if state == .fsAudioStreamPlaybackCompleted && hasNextItem() {
            ///这边记得修改播放模式
            currentPlaylistItemIndex = currentPlaylistItemIndex + 1
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
            
            /// 判断是否预加载下一个
            if !preloadNextPlaylistItemAutomatically {
                return
            }
            
            /// 判断是否有下一个，如果有的话，进入提前预加载
            if hasNextItem() {
                
                /// 这边记得修改播放模式
                let proxy = streams[currentPlaylistItemIndex + 1]
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


// MARK: - Add Nocation
extension AudioPlayerController {
    
    /// 添加中断通知和线路改变通知
    private func addInterruptionAndRouteChangeNotification() {
        
        self.removeNotification()
        NotificationCenter.default.addObserver(self, selector: #selector(self.interruption(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.routeChange(notification:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    /// 移除通知
    private func removeNotification() {
        
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
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


// MARK: - private
extension AudioPlayerController {
    
    /// MARK - 获取当前播放的项
    var currentPlaylistItem: AudioResources? {
        
        if playlistItems.count > 0 {
            let playlistItem = playlistItems[currentPlaylistItemIndex]
            return playlistItem
        } else {
            return nil
        }
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
    
    
    /// 开始播放定定时器
    private func startPlayerTimer() {
        
        playTimer?.invalidate()
        playTimer = Timer(timeInterval: 1,
                          target: WeakProxy(target: self),
                          selector: #selector(updateTime),
                          userInfo: nil,
                          repeats: true)
        RunLoop.current.add(playTimer!, forMode: .common)
    }
    
    
    /// 停止播放定时器
    private func stopPlayerTimer() {
        playTimer?.invalidate()
    }
    
    
    /// 刷新计时器
    @objc private func updateTime() {
        
        DispatchQueue.main.async {
         
            let currentTimePlayed = self.audioStream.currentTimePlayed
            let currentTime = TimeInterval(currentTimePlayed.playbackTimeInSeconds * 1000)
            let progress = currentTimePlayed.position
            
            self.delegate?.audioController(self,
                                           currentTime: TimeInterval(currentTime),
                                           progress: progress)
        }
    }
    
    /// 开始进度定时器
    private func startBufferTimer() {

        bufferTimer?.invalidate()
        bufferTimer = Timer(timeInterval: 0.5,
                            target: WeakProxy(target: self),
                            selector: #selector(updateBuffer),
                            userInfo: nil,
                            repeats: true)
        RunLoop.current.add(bufferTimer!, forMode: .common)
    }
    
    
    /// 停止进度定时器
    private func stopBufferTimer() {
        bufferTimer?.invalidate()
    }
    
    
    /// 刷新进度
    @objc private func updateBuffer() {
        
        DispatchQueue.main.async {
            
            let preBuffer: Float = Float(self.audioStream.prebufferedByteCount)
            let contentLength: Float = Float(self.audioStream.contentLength)
            
            // 这里获取的进度不能准确地获取到1
            var bufferProgress = contentLength > 0 ? preBuffer / contentLength : 0
            
            // 为了能使进度精准到1,做特殊处理
            let buffer: Int = Int(bufferProgress + 0.5)
            
            if bufferProgress > 0.9 && buffer >= 1 {
                self.stopBufferTimer()
                // 这里把进度设置为1，防止进度条出现不准确的情况
                bufferProgress = 1.0
                self.bufferState = .finished
                
            } else {
                self.bufferState = .buffering
            }
            self.delegate?.audioController(self, bufferProgress: bufferProgress)
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
        
        if playerState == .paused {
            resume()
        } else {
            audioStream.play()
        }
        
        /// 如果缓冲未完成
        if bufferState != .finished {
            bufferState = .none
            startBufferTimer()
        }
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
    
    /// MARK - 删除所有缓存(目前还不支持单个删除)
    public func removeCache() throws {
        
        if isPlaying() {
            //正在播放不能删除缓存
            throw NSError(domain: "com.mike.music", code: 9, userInfo: nil)
        }
        
        DispatchQueue.main.async {
            
            let deletePath: (_ path: String) -> Void = { path in
                let path = "\(self.cacheDirectory!)/\(path)"
                try? FileManager.default.removeItem(atPath: path)
            }
            
            let _ = try? FileManager.default.contentsOfDirectory(atPath: self.cacheDirectory)
                .filter { $0.hasPrefix("FSCache-") }
                .map(deletePath)
        }
    }
}
