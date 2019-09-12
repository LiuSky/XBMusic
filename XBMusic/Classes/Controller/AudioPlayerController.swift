//
//  AudioPlayerController.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//  iOS9注册观察者不需要移除事件  https://useyourloaf.com/blog/unregistering-nsnotificationcenter-observers-in-ios-9


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
    
    /// 当前播放的项
    public var currentPlaylistItem: AudioResources? {
        
        if playlistItems.count > 0 {
            let playlistItem = playlistItems[currentPlaylistItemIndex]
            return playlistItem
        } else {
            return nil
        }
    }
    
    /// 播放模式(默认是循环)
    public var playerMode: AudioPlayerMode = AudioPlayerMode.loop
    
    
    /// MARK - private
    /// 当前播放列表索引
    internal var currentPlaylistItemIndex: Int = 0
    
    /// 音频流代理数组
    internal var streams: [AudioStreamProxy] = []
    
    /// 播放列表数组
    var playlistItems: [AudioResources] = []
    
    /// 需要设置音量(默认为false)
    private(set) var needToSetVolume: Bool = false
    
    /// 正在进行歌曲切换
    internal var songSwitchInProgress: Bool = false
    
    /// 输出音量(默认1)
    private(set) var outputVolume: Float = 1.0
    
    /// 播放时间进度定时器
    private var playTimer: Timer?
    
    /// 缓冲状态定时器
    private var bufferTimer: Timer?
    
    /// 播放状态
    var playerState: AudioPlayerState = .none
    
    /// 缓冲状态
    var bufferState: AudioBufferState = .none
    
    /// 随机索引
    internal lazy var randomIndexs: [Int] = []
    
    /// 初始化
    public override init() {
        super.init()
        configCachePath()
        addObserver()
        addInterruptionAndRouteChangeNotification()
        addBackgroundAndForegroundNotification()
        addLockScreenOperationNotification()
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
        
        streams.forEach { $0.deactivate() }
        setActive(false)
        stopPlayerTimer()
        stopBufferTimer()
        debugPrint("释放音频播放控制器")
    }
}

// MARK: - private
extension AudioPlayerController {
    
    /// 配置默认缓存路径
    private func configCachePath() {
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if paths.count > 0 {
            cacheDirectory = paths[0]
        }
    }
    
    /// 当前播放音频
    internal var audioStream: FSAudioStream {
        
        let stream: FSAudioStream
        if streams.count == 0 {
            let proxy = AudioStreamProxy(audioController: self)
            streams.append(proxy)
        }
        
        let proxy = streams[currentPlaylistItemIndex]
        stream = proxy.audioStream
        return stream
    }
    
    
    /// 赋值音频代理对象
    internal func assignmentStreams() {
        
        streams = playlistItems.map { model -> AudioStreamProxy in
            let proxy = AudioStreamProxy(audioController: self)
            proxy.url = model.audioUrl
            return proxy
        }
    }
    
    /// 停用未激活的音频
    internal func deactivateInactivateStreams(_ currentActiveStream: Int) {
        
        for (index, item) in streams.enumerated() {
            if index != currentActiveStream {
                item.deactivate()
            }
        }
    }
    
    
    /// 开始播放定定时器
    internal func startPlayerTimer() {
        
        playTimer?.invalidate()
        playTimer = Timer(timeInterval: 1,
                          target: WeakProxy(target: self),
                          selector: #selector(updateTime),
                          userInfo: nil,
                          repeats: true)
        RunLoop.current.add(playTimer!, forMode: .common)
    }
    
    
    /// 停止播放定时器
    internal func stopPlayerTimer() {
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
            self.updatePlayingInfoCenter()
        }
    }
    
    /// 开始进度定时器
    internal func startBufferTimer() {
        
        bufferTimer?.invalidate()
        bufferTimer = Timer(timeInterval: 0.5,
                            target: WeakProxy(target: self),
                            selector: #selector(updateBuffer),
                            userInfo: nil,
                            repeats: true)
        RunLoop.current.add(bufferTimer!, forMode: .common)
    }
    
    
    /// 停止进度定时器
    internal func stopBufferTimer() {
        bufferTimer?.invalidate()
    }
    
    
    /// 刷新进度
    @objc internal func updateBuffer() {
        
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

