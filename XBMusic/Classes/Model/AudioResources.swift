//
//  AudioResources.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation

/// MARK - 资源协议
public protocol AudioResources {
    
    /// 播放地址
    var audioUrl: URL { get }
    
    /// 缓存是否启用
    var cacheEnabled: Bool { get }
}



// MARK: - Extension
extension AudioResources {
    
    /// 默认缓存
    public var cacheEnabled: Bool {
       return true
    }
}
