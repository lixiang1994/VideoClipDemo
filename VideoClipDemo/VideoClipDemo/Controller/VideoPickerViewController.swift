import UIKit
import Photos

class VideoPickerViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let manager = PHCachingImageManager()
    private lazy var options: PHFetchOptions = {
        $0.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: true)]
        return $0
    } ( PHFetchOptions() )
    private lazy var assets = PHAsset.fetchAssets(with: .video, options: options)
    
    private let loadingView = Loading.view(.system(.white))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "上传视频"
        
        setup()
        setupLayout()
        setupNotification()
        
        loadData()
    }
    
    private func setup() {
        view.addSubview(loadingView)
        loadingView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        loadingView.reloadButton.setTitle("没有视频", for: .normal)
        loadingView.reloadButton.setTitleColor(.white, for: .normal)
        loadingView.reload { [weak self] in self?.loadData() }
    }
    
    private func setupLayout() {
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalTo(collectionView)
        }
    }
    
    private func setupNotification() {
        PHPhotoLibrary.shared().register(self)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
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
    
    class func instance() -> VideoPickerViewController {
        return StoryBoard.main.instance()
    }
}

extension VideoPickerViewController {
    
    private func loadData() {
        loadingView.start()
        assets = PHAsset.fetchAssets(with: .video, options: options)
        collectionView.reloadData()
        if assets.count == 0 {
            loadingView.failure()
        } else {
            loadingView.stop()
        }
        DispatchQueue.main.async {
            let point = CGPoint(
                x: 0,
                y: self.collectionView.contentSize.height - self.collectionView.bounds.height
            )
            self.collectionView.setContentOffset(point, animated: false)
        }
    }
}

/// PHPhotoLibraryChangeObserver代理实现，图片新增、删除、修改开始后会触发
extension VideoPickerViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.loadData()
        }
    }
}

extension VideoPickerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        return CGSize(width: (screenWidth - 4) / 3.0, height: (screenWidth - 4) / 3.0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard assets[indexPath.row].duration >= 5 else {
            let alert = UIAlertController(
                title: "视频太短，请重新选择",
                message: "",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "好的", style: .cancel))
            present(alert, animated: true)
            return
        }
        
        let option = PHVideoRequestOptions()
        option.version = .current
        option.deliveryMode = .automatic
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (progress, error, bool, info) in
            print("\(progress) | \(bool)")
        }
        let asset = assets[indexPath.row]
        
        loadingView.start()
        manager.requestPlayerItem(forVideo: asset, options: option) {
            [weak self] (item, info) in
            guard let this = self else { return }
            guard let item = item else { return }
            DispatchQueue.main.async {
                this.loadingView.stop()
                let controller = VideoClipViewController.instance(
                    item: item
                )
                this.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

extension VideoPickerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "VideoPickerCell",
            for: indexPath
        ) as! VideoPickerCell
        cell.set(manager: manager, asset: assets[indexPath.row])
        return cell
    }
}
