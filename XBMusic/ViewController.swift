//
//  ViewController.swift
//  XBMusic
//
//  Created by xiaobin liu on 2019/3/12.
//  Copyright © 2019 Sky. All rights reserved.
//

import UIKit


/// MARK - 音频播放Demo
final class ViewController: UIViewController {

    /// 上一首按钮
    private lazy var prebutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: self.view.center.x/2 + 25, y: 100, width: 100, height: 50)
        temButton.setTitle("上一首", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForPre), for: .touchUpInside)
        return temButton
    }()
    
    
    /// 下一首按钮
    private lazy var nextbutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: prebutton.frame.origin.x, y: prebutton.frame.maxY + 50, width: 100, height: 50)
        temButton.setTitle("下一首", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForNext), for: .touchUpInside)
        return temButton
    }()
    
    /// 播放||暂停
    private lazy var playbutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: prebutton.frame.origin.x, y: nextbutton.frame.maxY + 50, width: 100, height: 50)
        temButton.setTitle("播放", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForPlay), for: .touchUpInside)
        return temButton
    }()
    
    /// 音频播放控制器
    private lazy var audioPlayerController: AudioPlayerController = {
        let temAudioPlayerController = AudioPlayerController(with: urls)
        temAudioPlayerController.delegate = self
        return temAudioPlayerController
    }()
    
    /// 播放资源
    private lazy var urls = ["http://ali.ixy123.com/upload/article/20180807/20180807045343948_犟龟.mp3",
                             "http://ali.ixy123.com/upload/article/20180717/20180717022859084_HAPPY DUCK.mp3",
                             "http://ali.ixy123.com/upload/article/20180717/20180717024153893_THE HOKEY POKEY.mp3",
                             "http://ali.ixy123.com/upload/article/20180326/20180326083839498_生气汤1.mp3",]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configView()
    }
    
    
    /// 配置View
    private func configView() {
        
        view.addSubview(prebutton)
        view.addSubview(nextbutton)
        view.addSubview(playbutton)
    }

    /// 上一首
    @objc private func eventForPre() {
        //let vc = AViewController()
        ///self.navigationController?.pushViewController(vc, animated: true)
        audioPlayerController.playPreviousItem()
    }
    
    /// 下一首
    @objc private func eventForNext() {
        audioPlayerController.playNextItem()
    }
    
    /// 播放
    @objc private func eventForPlay() {
        
        if audioPlayerController.isPlaying() {
            audioPlayerController.pause()
            playbutton.setTitle("播放", for: .normal)
        } else {
            
            
            audioPlayerController.play()
            playbutton.setTitle("暂停", for: .normal)
        }
    }
}


// MARK: - AudioPlayerControllerDelegate
extension ViewController: AudioPlayerControllerDelegate {
    
    func audioController(_ audioController: AudioPlayerController, statusChanged state: AudioPlayerState, resources: AudioResources?) {
        debugPrint(state)
        debugPrint(resources)
    }
    
    
    func audioController(_ audioController: AudioPlayerController, currentTime: TimeInterval, progress: Float) {
        debugPrint("当前播放时间:\(currentTime.timeMsString)")
        debugPrint("播放进度:\(progress)")
    }
    
    func audioController(_ audioController: AudioPlayerController, totalTime: TimeInterval) {
        debugPrint("总时间:\(totalTime.timeMsString)")
    }
    
    func audioController(_ audioController: AudioPlayerController, bufferProgress: Float) {
        debugPrint("缓存进度:\(bufferProgress)")
    }
}


// MARK: - AudioResources
extension String: AudioResources {
    
    public var audioUrl: URL {
        return URL(string: self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    }
}

