//
//  AudioPlayerController+.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation
import FreeStreamer


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
        /// 这边记得修改播放模式
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
        
        /// 这边记得修改播放模式
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
        
        /// 这边记得修改播放模式
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
        /// 目前市面上大部分都是可以无限循环的
        return true
        //return hasMultiplePlaylistItems() && currentPlaylistItemIndex + 1 < playlistItems.count
    }
    
    /// MARK - 是否有上一个
    public func hasPreviousItem() -> Bool {
        /// 目前市面上大部分都是可以无限循环的
        return true
        //return hasMultiplePlaylistItems() && currentPlaylistItemIndex != 0
    }
    
    /// MARK - 播放下一个
    public func playNextItem() {
        
        /// 这边注意模式播放方式(后续添加)
        if hasNextItem() {
            songSwitchInProgress = true
            audioStream.stop()
            deactivateInactivateStreams(currentPlaylistItemIndex)
            currentPlaylistItemIndex = calculatePlayer(playerMode, true)
            play()
        }
    }
    
    /// MARK - 播放上一个
    public func playPreviousItem() {
        
        /// 这边注意模式播放方式(后续添加)
        if hasPreviousItem() {
            songSwitchInProgress = true
            audioStream.stop()
            deactivateInactivateStreams(currentPlaylistItemIndex)
            currentPlaylistItemIndex = calculatePlayer(playerMode, false)
            play()
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
        audioStream.seek(to: position)
    }
    
    /// MARK - 设置播放速率 0.5 - 2.0， 1.0是正常速率
    public func setPlayerPlayRate(_ playRate: Float) {
        
        var temPlayRate: Float = 1.0
        if playRate < 0.5 { temPlayRate = 0.5 }
        if playRate > 2.0 { temPlayRate = 2.0 }
        audioStream.setPlayRate(temPlayRate)
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
