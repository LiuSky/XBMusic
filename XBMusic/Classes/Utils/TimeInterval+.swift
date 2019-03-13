//
//  TimeInterval+.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/13.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit
import Foundation


// MARK: - 扩展TimeInterval
extension TimeInterval {
    
    /// 秒的字符串
    public var timeMsString: String {
        return (self.rounded()/1000).timeSecString
    }

    public var timeSecString: String {

        if Int(self.rounded()) > 3600 {

            let hour: Int = Int(self.rounded()) / 3600
            let seconds: Int = Int(self.rounded()) % 3600 / 60
            let minutes: Int = Int(self.rounded()) % 3600 % 60
            return String(format: "%02ld:%02ld:%02ld", hour, minutes, seconds)

        } else {
            
            let seconds: Int = Int(self.rounded()) % 60
            let minutes: Int = Int(self.rounded()) / 60
            return String(format: "%02ld:%02ld", minutes, seconds)
        }
    }
}
