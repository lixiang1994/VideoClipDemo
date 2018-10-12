import UIKit
import AVFoundation
import Photos

class VideoClipViewController: UIViewController {
    
    // 当前正在播放的视频的信息
    var item: AVPlayerItem!
    
    private lazy var player = AVPlayer()
    private lazy var playerLayer = AVPlayerLayer()
    private var playerTimeObserver: Any?
    
    private var beginTime: Double { return getBeginTime() }
    private var endTime: Double { return getEndTime() }
    
    /// 底部的裁剪模块
    
    // 最长时间限制
    private var maxTime = 15.0
    private let minTime = 5.0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var clipLeftHandle: UIView!
    @IBOutlet weak var clipRightHandle: UIView!
    @IBOutlet weak var leftShadowViewWidthConstarint: NSLayoutConstraint!
    @IBOutlet weak var rightShadowViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var clipTimeLabel: UILabel!
    @IBOutlet weak var playView: UIView!
    
    struct Thumbnail {
        let time: Double
        let size: CGSize
        var image: UIImage?
    }
    
    private var thumbnails: [Thumbnail] = []
    
    private var clipLeftBeginPoint: CGPoint = .zero
    private var clipRightBeginPoint: CGPoint = .zero
    
    private var videoURL: URL?
    private var exportSession: AVAssetExportSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setupPlayer()
        setupGestures()
        setupNotification()
        loadThumbnails()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.pause()
    }
    
    private func setup() {
        view.layoutIfNeeded()
        view.backgroundColor = .black
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        // 确定视频的总时长
        let totalTime = item.asset.duration.seconds
        maxTime = totalTime > maxTime ? maxTime : totalTime
        clipTimeLabel.text = "已读取\(Int(maxTime))秒"
    }
    
    private func setupPlayer() {
        player.replaceCurrentItem(with: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = playView.bounds
        playerLayer.videoGravity = .resizeAspect
        playView.layer.insertSublayer(playerLayer, at: 0)
        
        // 播放
        player.play()
        // 添加监听
        addObserver()
    }
    
    func setupGestures() {
        
        let leftPan = UIPanGestureRecognizer(target: self, action: #selector(leftPanAction(_:)))
        clipLeftHandle.addGestureRecognizer(leftPan)
        
        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(rightPanAction(_:)))
        clipRightHandle.addGestureRecognizer(rightPan)
    }
    
    private func setupNotification() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    class func instance() -> VideoClipViewController {
        return StoryBoard.main.instance()
    }

    class func instance(item: AVPlayerItem) -> VideoClipViewController {
        let vc = instance()
        vc.item = item
        return vc
    }
    
    deinit {
        exportSession?.cancelExport()
        removeObserver()
        print("VideoClipViewController deinit")
    }
}

extension VideoClipViewController {
    
    private func addObserver() {
        removeObserver()
        // 当前播放时间 (间隔: 每秒10次)
        let interval = CMTime(value: 1, timescale: 10)
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) {
            [weak self] (time) in
            guard let this = self else { return }
            if time.seconds >= this.endTime {
                this.player.pause()
                this.seekTo(time: this.beginTime) {
                    this.player.play()
                }
            }
        }
    }
    
    private func removeObserver() {
        guard let observer = playerTimeObserver else { return }
        playerTimeObserver = nil
        player.removeTimeObserver(observer)
    }
    
    /// 调到播放时间
    func seekTo(time: Double, completion: (()->Void)? = nil) {
        guard player.status == .readyToPlay else { return }
        guard let item = player.currentItem else { return }
        
        // 暂时移除监听
        removeObserver()
        
        let changeTime = CMTimeMakeWithSeconds(time, preferredTimescale: 1)
        item.seek(to: changeTime, completionHandler: { [weak self] (finish) in
            guard finish else { return }
            // 恢复监听
            self?.addObserver()
            completion?()
        })
    }
}

extension VideoClipViewController {
    
    @objc func willEnterForeground(_ notification: NSNotification) {
        player.play()
    }
    
    @objc func didEnterBackground(_ notification: NSNotification) {
        player.pause()
    }
}

extension VideoClipViewController {
    
    @IBAction func closeAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func exportVideo(_ sender: UIButton) {
        
        sender.startLoading()
        
        clip(asset: item.asset, begin: beginTime, end: endTime) {
            [weak self] (result) in
            guard let this = self else { return }
            
            if result, let url = this.videoURL {
                let alert = UIAlertController(
                    title: "缓存URL: \(url)",
                    message: "",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "好的", style: .cancel))
                this.present(alert, animated: true)
                
            } else {
                let alert = UIAlertController(
                    title: "导出失败",
                    message: "",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "好的", style: .cancel))
                this.present(alert, animated: true)
            }
            sender.stopLoading()
        }
    }
}

extension VideoClipViewController {
    
    @objc func leftPanAction(_ pan: UIPanGestureRecognizer) {
        let touchPoint = pan.location(in: nil)
        switch pan.state {
        case .began:
            clipLeftBeginPoint = touchPoint
            
        case .changed:
            let distance = pan.translation(in: view).x
            var width = clipLeftBeginPoint.x + distance
            guard leftCanDraging(distance: distance) else {
                return
            }
            let endX = clipRightHandle.center.x
            let minWidth = minTime / getSingleTime()
            let tempWidth = endX - CGFloat(minWidth)
            if width >= tempWidth {
                width = tempWidth
            }
            leftShadowViewWidthConstarint.constant = width > 30 ? width : 30
            view.layoutIfNeeded()
            
        case .ended, .cancelled, .failed:
            clipLeftBeginPoint = .zero
            dragEnd()
            
        default: break
        }
    }
    
    @objc func rightPanAction(_ pan: UIPanGestureRecognizer) {
        let touchPoint = pan.location(in: view)
        switch pan.state {
        case .began:
            clipRightBeginPoint = touchPoint
            
        case .changed:
            let screenWidth = UIScreen.main.bounds.width
            let distance = pan.translation(in: view).x
            var width = (screenWidth - clipRightBeginPoint.x) - distance
            guard rightCanDraging(distance: distance) else { return }
            
            let beginX = clipLeftHandle.center.x
            let minWidth = minTime / getSingleTime()
            let tempWidth = screenWidth - (beginX + CGFloat(minWidth))
            if width >= tempWidth {
                width = tempWidth
            }
            rightShadowViewWidthConstraint.constant = width > 30 ? width : 30
            view.layoutIfNeeded()
            
        case .ended, .cancelled, .failed:
            clipRightBeginPoint = .zero
            dragEnd()
            
        default: break
        }
    }
    
    func leftCanDraging(distance: CGFloat) -> Bool {
        let duration = endTime - beginTime
        
        if distance > 0 {
            if duration >= minTime {
                clipTimeLabel.text = "已读取\(Int(duration))秒"
                return true
            }
        } else {
            if duration <= maxTime {
                clipTimeLabel.text = "已读取\(Int(duration))秒"
                return true
            }
        }
        return false
    }
    
    func rightCanDraging(distance: CGFloat) -> Bool {
        let duration = endTime - beginTime
        if distance > 0 {
            // 右滑动
            if duration <= maxTime {
                clipTimeLabel.text = "已读取\(Int(duration))秒"
                return true
            }
        } else {
            if duration >= minTime {
                clipTimeLabel.text = "已读取\(Int(duration))秒"
                return true
            }
        }
        return false
    }
    
    func dragEnd() {
        player.pause()
        seekTo(time: beginTime) { [weak self] in
            self?.player.play()
        }
    }
    
    func getSingleTime() -> Double {
        let maxWidth = Double(collectionView.bounds.width - 60)
        return maxTime / maxWidth
    }
    
    func getBeginTime() -> Double {
        let offset = collectionView.contentOffset.x + collectionView.contentInset.left
        var width: CGFloat = 0
        let totalTime = item.asset.duration.seconds
        if totalTime <= maxTime {// 总时间小于最大时间限制
            width = clipLeftHandle.center.x - collectionView.contentInset.left
        } else {
            if offset == 0 {
                // collectionview没有向左滑动
                width = clipLeftHandle.center.x - collectionView.contentInset.left
            } else if offset <= collectionView.contentInset.left {
                let dis = collectionView.contentInset.left - offset
                width = clipLeftHandle.center.x - dis
            } else {
                width = (offset - collectionView.contentInset.left) + clipLeftHandle.center.x
            }
        }
        return Double(width) * getSingleTime()
    }

    func getEndTime() -> Double {
        let offset = collectionView.contentOffset.x + collectionView.contentInset.left
        var width: CGFloat = 0
        let totalTime = item.asset.duration.seconds
        if totalTime <= maxTime {
            width = clipRightHandle.center.x - collectionView.contentInset.left
        } else {
            if offset == 0 {
                width = clipRightHandle.center.x - collectionView.contentInset.left
            } else if offset <= collectionView.contentInset.left {
                let dis = collectionView.contentInset.left - offset
                width = clipRightHandle.center.x - dis
            } else {
                width = (offset - collectionView.contentInset.left) + clipRightHandle.center.x
            }
        }
        return Double(width) * getSingleTime()
    }
}

extension VideoClipViewController {
    
    func loadThumbnails() {
        
        let asset = item.asset
        // 最大宽度
        let maxWidth = Double(collectionView.bounds.width - 60)
        // 总时长
        let totalTime = asset.duration.seconds
        // 单像素时长
        let singleTime = maxTime / maxWidth
        // 总宽度
        let totalWidth = totalTime / singleTime
        
        let height = Double(collectionView.bounds.height)
        let track = asset.tracks(withMediaType: .video).first
        let transform = track?.preferredTransform ?? .identity
        var size = track?.naturalSize ?? CGSize(width: height, height: height)
        size = size.applying(transform) // ⚠️视频尺寸会受视频Transform影响 需要转换
        let ratio = Double(abs(size.width) / abs(size.height))
        let width = Double(height * ratio)
        let count = ceil(totalWidth / width)
        let imageSize = CGSize(width: totalWidth / count, height: height)
        let imageCount = Int(count)
        
        let fps = asset.tracks(withMediaType: .video).last?.nominalFrameRate ?? 0
        let totalFrames = totalTime * Double(fps)
        let perFrame = totalFrames / Double(imageCount)
        var times: [NSValue] = []
        
        var frame = 0.0
        while frame < totalFrames {
            let time = CMTimeMake(value: Int64(frame), timescale: Int32(fps))
            let value = NSValue(time: time)
            times.append(value)
            frame += perFrame
        }
        
        // 创建占位数据
        thumbnails = times.map({ (value) -> Thumbnail in
            Thumbnail(time: value.timeValue.seconds, size: imageSize, image: nil)
        })
        collectionView.reloadData()
        
        let generator = AVAssetImageGenerator(asset: item.asset)
        // 防止时间出现偏差
        generator.requestedTimeToleranceBefore = CMTime.zero
        generator.requestedTimeToleranceAfter = CMTime.zero
        // 截图的时候调整到正确的方向
        generator.appliesPreferredTrackTransform = true
        generator.generateCGImagesAsynchronously(forTimes: times) {
            [weak self] (requestedTime, cgimage, actualTime, result, error) in
            guard let this = self else { return }
            
            switch result {
            case .succeeded:
                guard
                    let cgImage = cgimage,
                    let index = this.thumbnails.index(where: { $0.time == requestedTime.seconds }) else {
                        return
                }
                let image = UIImage(cgImage: cgImage).scaled(toHeight: CGFloat(height))
                DispatchQueue.main.async {
                    let indexPath = IndexPath(item: index, section: 0)
                    this.thumbnails[index].image = image
                    this.collectionView.reloadItems(at: [indexPath])
                }
                
            case .cancelled:
                break
            case .failed:
                break
            }
        }
    }
}

extension VideoClipViewController {
    
    private func clip(asset: AVAsset,
                      begin: Double,
                      end: Double,
                      completion: @escaping (Bool) -> Void) {
        guard
            !asset.tracks(withMediaType: .video).isEmpty,
            !asset.tracks(withMediaType: .audio).isEmpty else {
            completion(false)
            return
        }
        
        let composition = AVMutableComposition()
        let assetVideoTrack = asset.tracks(withMediaType: .video)[0]
        let assetAudioTrack = asset.tracks(withMediaType: .audio)[0]
        
        let fps = asset.tracks(withMediaType: .video).last?.nominalFrameRate ?? 0
        let startDuration = CMTimeMakeWithSeconds(Float64(begin), preferredTimescale: Int32(fps))
        let duration = CMTimeMakeWithSeconds(Float64(end - begin), preferredTimescale: Int32(fps))
        
        let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        do{
            try compositionVideoTrack?.insertTimeRange(
                CMTimeRangeMake(start: startDuration, duration: duration),
                of: assetVideoTrack,
                at: CMTime.zero
            )
            compositionVideoTrack?.preferredTransform = assetVideoTrack.preferredTransform
        } catch {
            completion(false)
            return
        }
        
        let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        do {
            try compositionAudioTrack?.insertTimeRange(
                CMTimeRangeMake(start: startDuration, duration: duration),
                of: assetAudioTrack,
                at: CMTime.zero
            )
        } catch {
            completion(false)
            return
        }
        
        export(composition: composition, completion: completion)
    }
    
    
    /// 导出视频
    private func export(composition: AVMutableComposition, completion: @escaping (Bool) -> Void) {
        
        var path = NSTemporaryDirectory()
        path = path.appending("temp_video.mp4")
        
        let manager = FileManager.default
        // 移除已经存在的文件
        if manager.fileExists(atPath: path) {
            do {
                try manager.removeItem(atPath: path)
            } catch {
                completion(false)
            }
        }
        guard let asset = composition.copy() as? AVAsset else {
            completion(false)
            return
        }
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080) else {
            completion(false)
            return
        }
        session.outputURL = URL(fileURLWithPath: path)
        session.outputFileType = .mp4
        session.shouldOptimizeForNetworkUse = true
        session.exportAsynchronously(completionHandler: { [weak self] in
            guard let this = self else { return }
            
            DispatchQueue.main.async {
                this.exportSession = nil
                switch session.status {
                case .completed:
                    this.videoURL = session.outputURL
                    completion(true)
                    print("---裁剪后的视频地址------ \(String(describing: this.videoURL))")
                    
                case .failed:
                    completion(false)
                    print("---导出错误-- \(String(describing: session.error))")
                    
                case .cancelled:
                    completion(false)
                    print("---取消导出-- \(String(describing: session.error))")
                    
                case .waiting:
                    print("---等待中---")
                case .exporting:
                    print("---导出中---")
                case .unknown:
                    print("---未知状态---")
                }
            }
        })
        
        exportSession = session
    }
}

extension VideoClipViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "VideoClipCell",
            for: indexPath
        ) as! VideoClipCell
        cell.set(image: thumbnails[indexPath.item].image)
        return cell
    }
}

extension VideoClipViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return thumbnails[indexPath.item].size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if
            !scrollView.isTracking,
            !scrollView.isDragging,
            !scrollView.isDecelerating {
            dragEnd()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if
            !decelerate,
            scrollView.isTracking,
            !scrollView.isDragging,
            !scrollView.isDecelerating {
            dragEnd()
        }
    }
}
