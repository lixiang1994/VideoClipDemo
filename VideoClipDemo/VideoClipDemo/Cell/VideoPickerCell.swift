import UIKit
import Photos

class VideoPickerCell: UICollectionViewCell {
    
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var videoDuration: UILabel!
    
    private var localIdentifier = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        videoImage.contentMode = .scaleAspectFill
    }
    
    func set(manager: PHCachingImageManager, asset: PHAsset) {
        
        localIdentifier = asset.localIdentifier
       
        videoImage.image = nil
        videoDuration.text = ""
        
        let option = PHImageRequestOptions()
        option.version = .current
        option.deliveryMode = .highQualityFormat
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (progress, error, bool, info) in
            print("\(progress) | \(bool)")
        }
        
        manager.requestImage(for: asset, targetSize: bounds.size, contentMode: .aspectFill, options: option) { [weak self] (image, info) in
            guard let this = self else { return }
            guard this.localIdentifier == asset.localIdentifier else { return }
            if let info = info, let cloud = info[PHImageResultIsInCloudKey] as? Int {
                print(cloud)
            }
            this.videoImage.image = image
            this.videoDuration.text = VideoPickerCell.timeToHMS(time: asset.duration)
        }
    }
    
    static func timeToHMS(time: TimeInterval) -> String {
        
        let format = DateFormatter()
        if time / 3600 >= 1 {
            format.dateFormat = "HH:mm:ss"
        } else {
            format.dateFormat = "mm:ss"
        }
        let date = Date(timeIntervalSince1970: time)
        let string = format.string(from: date)
        return string
    }
}
