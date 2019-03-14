//
//  AudioPlayerProtocol.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/13.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation


/// MARK - 音频播放协议
public protocol AudioPlayerProtocol {
    
    /// MARK - 播放资源
    func play(from resources: AudioResources)

    /// MARK - 播放列表
    func play(fromPlaylist playlist: [AudioResources])
    
    /// MARK - 播放列表索引开始
    func play(fromPlaylist playlist: [AudioResources], itemIndex index: Int)
    
    /// MARK - 在指定的索引处播放播放列表项
    func playItem(at index: Int)
    
    /// MARK - 返回播放列表项的数量
    func countOfItems() -> Int
    
    /// MARK - 添加一个项目到播放列表
    func addItem(_ item: AudioResources)
    
    /// MARK - 将一个项目添加到特定位置的播放列表中
    func insertItem(_ newItem: AudioResources, at index: Int)
    
    /// MARK - 将已在播放列表中的项目移动到播放列表中的不同位置
    func moveItem(at from: Int, _ to: Int)
    
    /// MARK - 替换播放列表项
    func replaceItem(at index: Int, with item: AudioResources)
    
    /// MARK - 删除播放列表项
    func removeItem(at index: Int)
    
    /// MARK - 播放
    func play()
    
    /// MARK - 停止播放
    func stop()
    
    /// MARK - 暂停
    func pause()
    
    /// MARK - 恢复
    func resume()
    
    /// MARK - 是否正在播放
    func isPlaying() -> Bool
    
    /// MARK - 是否有多个播放列表项
    func hasMultiplePlaylistItems() -> Bool
    
    /// MARK - 是否有下一个
    func hasNextItem() -> Bool
    
    /// MARK - 是否有上一个
    func hasPreviousItem() -> Bool
    
    /// MARK - 播放下一个
    func playNextItem()
    
    /// MARK - 播放上一个
    func playPreviousItem()
    
    /// MARK - 从某个进度开始播放
    func setPlayerProgress(_ progress: Float)
    
    /// MARK - 设置播放速率 0.5 - 2.0， 1.0是正常速率
    func setPlayerPlayRate(_ playRate: Float)
    
    /// MARK - 删除缓存
    func removeCache() throws
}
