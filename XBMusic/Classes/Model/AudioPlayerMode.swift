//
//  AudioPlayerMode.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/13.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation


/// MARK - 播放模式
///
/// - loop: 循环播放
/// - one: 单曲播放
/// - random: 随机播放
public enum AudioPlayerMode: Int {
    
    case loop
    case one
    case random
}


// MARK: - CustomStringConvertible
extension AudioPlayerMode: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .loop:
            return "循环播放"
        case .one:
            return "单曲播放"
        case .random:
            return "随机播放"
        }
    }
}
