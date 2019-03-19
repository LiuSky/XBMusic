//
//  AudioMPMediaItem.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/19.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import Foundation


/// MARK - 锁屏界面属性协议
public protocol AudioMPMediaItem {
    
    /// 标题
    var mediaTitle: String { get }
    
    /// 作者
    var mediaArtist: String { get }
    
    /// 封面
    var mediaArtwork: UIImage { get }
}
