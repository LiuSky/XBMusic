//
//  AudioPlayerController+PlayerModeCalculate.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation


// MARK: - 播放模式算法
extension AudioPlayerController {
    
    /// 计算播放索引
    /// 1.循环播放(当播放到最后一个的时候会重置列表,然后从第一个重新开始)
    /// 2.单曲循环(不断的重复播放)
    /// 3.随机播放(每次被播放过的歌曲的索引会被移除,直到移除到最后一个。然后重新开始)
    /// - Parameters:
    ///   - mode: 播放模式
    ///   - hasNextItem: 是否是下一曲
    /// - Returns: Int
    open func calculatePlayer(_ mode: AudioPlayerMode, _ hasNextItem: Bool) -> Int {
        
        switch mode {
        case .loop:
            return calculateLoop(hasNextItem)
        case .one:
            return calculateOne()
        case .random:
            return calculateRandom(hasNextItem)
        }
    }
    
    
    /// 计算循环
    ///
    /// - Parameter hasNextItem: 是否是下一曲
    /// - Returns: Int
    private func calculateLoop(_ hasNextItem: Bool) -> Int {
        
        if hasNextItem {
            
            if currentPlaylistItemIndex + 1 == playlistItems.count {
                /// 重置播放列表为0
                return 0
            } else {
                return currentPlaylistItemIndex + 1
            }
            
        } else {
            
            if currentPlaylistItemIndex == 0 {
                /// 播放最后一首歌
                return playlistItems.count - 1
            } else {
                return currentPlaylistItemIndex - 1
            }
        }
    }
    
    
    /// 计算单曲循环
    ///
    /// - Returns: <#return value description#>
    private func calculateOne() -> Int {
        return currentPlaylistItemIndex
    }
    
    
    /// 计算随机(待优化)
    ///
    /// - Returns: <#return value description#>
    private func calculateRandom(_ hasNextItem: Bool) -> Int {
        
        /*
         1.如果洗牌的数量与播放列表不相等
         */
        if randomIndexs.count != playlistItems.count {
            randomIndexs = (0..<playlistItems.count).shuffled()
        }
        
        /// 查找当前播放的索引位置
        let idx = randomIndexs.firstIndex(of: currentPlaylistItemIndex)!
        
        if hasNextItem {
            
            let next = idx + 1
            if next > playlistItems.count - 1 {
                return randomIndexs[0]
            } else {
                return randomIndexs[next]
            }
            
        } else {
            
            let previous = idx - 1
            if previous < 0  {
                return randomIndexs[randomIndexs.count-1]
            } else {
                return randomIndexs[previous]
            }
        }
    }
}
