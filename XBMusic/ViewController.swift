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
    
    /// 列表
    private lazy var tableView: UITableView = {
        let temTableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 400))
        temTableView.backgroundColor = UIColor.white
        temTableView.dataSource = self
        temTableView.delegate = self
        temTableView.rowHeight = 50
        temTableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        temTableView.tableFooterView = UIView()
        return temTableView
    }()
    
    
    /// 模式按钮
    private lazy var modebutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: 10, y: self.view.frame.height - 100, width: 100, height: 50)
        temButton.setTitle(AudioPlayerMode.loop.description, for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForMode), for: .touchUpInside)
        return temButton
    }()
    
    
    /// 上一首按钮
    private lazy var prebutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: modebutton.frame.maxX + 10, y: modebutton.frame.origin.y, width: 70, height: 50)
        temButton.setTitle("上一首", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForPre), for: .touchUpInside)
        return temButton
    }()
    
    
    /// 播放||暂停
    private lazy var playbutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: prebutton.frame.maxX + 10, y: modebutton.frame.origin.y, width: 70, height: 50)
        temButton.setTitle("播放", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForPlay), for: .touchUpInside)
        return temButton
    }()
    
    
    /// 下一首按钮
    private lazy var nextbutton: UIButton = {
        let temButton = UIButton(type: .custom)
        temButton.backgroundColor = UIColor.red
        temButton.frame = CGRect(x: playbutton.frame.maxX + 10, y: modebutton.frame.origin.y, width: 70, height: 50)
        temButton.setTitle("下一首", for: .normal)
        temButton.setTitleColor(UIColor.white, for: .normal)
        temButton.addTarget(self, action: #selector(eventForNext), for: .touchUpInside)
        return temButton
    }()
    
    /// 音频播放控制器
    private lazy var audioPlayerController: AudioPlayerController = {
        let temAudioPlayerController = AudioPlayerController(with: urls)
        temAudioPlayerController.delegate = self
        return temAudioPlayerController
    }()
    
    /// 播放资源
    private lazy var urls = [Test(name: "犟龟",
                                  url: "http://ali.ixy123.com/upload/article/20180807/20180807045343948_犟龟.mp3"),
                             Test(name: "HAPPY DUCK",
                                  url: "http://ali.ixy123.com/upload/article/20180717/20180717022859084_HAPPY DUCK.mp3"),
                             Test(name: "HOKEY POKEY",
                                  url: "http://ali.ixy123.com/upload/article/20180717/20180717024153893_THE HOKEY POKEY.mp3"),
                             Test(name: "生气汤",
                                  url: "http://ali.ixy123.com/upload/article/20180326/20180326083839498_生气汤1.mp3")
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configView()
    }
    
    
    /// 配置View
    private func configView() {
        
        view.addSubview(tableView)
        view.addSubview(modebutton)
        view.addSubview(prebutton)
        view.addSubview(nextbutton)
        view.addSubview(playbutton)
    }
    
    /// 模式切换
    @objc private func eventForMode() {
        
        switch audioPlayerController.playerMode {
        case .loop:
            audioPlayerController.playerMode = .one
        case .one:
            audioPlayerController.playerMode = .random
        case .random:
            audioPlayerController.playerMode = .loop
        }
        modebutton.setTitle(audioPlayerController.playerMode.description, for: .normal)
    }

    /// 上一首
    @objc private func eventForPre() {
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
        self.navigationItem.title = (resources as! Test).name
        debugPrint(state)
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


// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self))!
        cell.textLabel?.text = urls[indexPath.row].name
        return cell
    }
}


// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        audioPlayerController.playItem(at: indexPath.row)
    }
}



/// MARK - 测试结构体
public struct Test {
    
    let name: String
    let url: String
}

extension Test: AudioResources {
    public var audioUrl: URL {
        return URL(string: url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
    }
}
