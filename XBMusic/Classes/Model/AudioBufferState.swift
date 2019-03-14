//
//  AudioBufferState.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/14.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation


/// MARK - 播放器缓冲状态
///
/// - none: 空
/// - buffering: 缓冲中
/// - finished: 完成了
public enum AudioBufferState: Int {
    
    case none
    case buffering
    case finished
}


// MARK: - CustomStringConvertible
extension AudioBufferState: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .none:
            return "空"
        case .buffering:
            return "缓冲中"
        case .finished:
            return "完成了"
        }
    }
}

