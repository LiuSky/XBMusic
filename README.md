## Requirements:
- **iOS** 9.0+
- Xcode 10.1+
- Swift 4.2+

## Demo Figure
<p align="center">
<img src="https://github.com/LiuSky/XBMusic/blob/master/1.png?raw=true" title="演示图">
</p>


## Features
- [x] 播放音频列表
- [x] 播放模式: 循环播放, 单曲播放, 随机播放
- [x] 播放器状态改变回调
- [x] 播放时间（单位：毫秒)、总时间（单位：毫秒）、进度（播放时间 / 总时间）回调
- [x] 总时间（单位：毫秒）
- [x] 缓冲进度
- [x] 预先缓存下一个播放音频
- [x] 自定义缓存路径,清除缓存
- [x] 添加一个项目到播放列表
- [x] 将一个项目添加到特定位置的播放列表中
- [x] 将已在播放列表中的项目移动到播放列表中的不同位置
- [x] 替换播放列表项等
- [x] 锁屏控制操作
- [x] interruptionNotification, routeChangeNotification 打断音频通知处理


## Usage
### 1.初始化
```swift 
private lazy var audioPlayerController: AudioPlayerController = {
    let temAudioPlayerController = AudioPlayerController()
    temAudioPlayerController.delegate = self
    return temAudioPlayerController
}()
``` 

### 2.添加播放列表
```swift 
audioPlayerController.play(fromPlaylist: url)
```

### 3.播放、暂停、上一首、下一首、播放模式
```
audioPlayerController.play()
audioPlayerController.pause()
audioPlayerController.playPreviousItem()
audioPlayerController.playNextItem()
audioPlayerController.playerMode = .one
```

## Rely on
<ul>
<li><a href="https://github.com/muhku/FreeStreamer"><code>FreeStreamer</code></a></li>
</ul>

## License
XBMusic is released under an MIT license. See [LICENSE](LICENSE) for more information.