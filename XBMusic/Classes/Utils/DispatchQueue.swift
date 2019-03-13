//
//  DispatchQueue+.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//

import Foundation

// MARK: - 操作队列扩展
extension DispatchQueue {
    
    /// 主线程执行
    public func mainThread(_ block: @escaping () -> ()) {
        
        if Thread.isMainThread {
            block()
        }
        else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
