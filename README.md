# SwiftyVideoExporter 

Here is a some raw code that will help you export video from gallery, compress it, crop, change aspect ratio if needed and set new bitrate using this package.
Sample code might not be compilable, but you get the idea :)

```Swift

let videoSettings = [
  AVVideoCodecKey: AVVideoCodecType.h264,
  AVVideoWidthKey: targetSize.width,
  AVVideoHeightKey: targetSize.height,
  AVVideoCompressionPropertiesKey: [
      AVVideoAverageBitRateKey: 1024_000,
      AVVideoProfileLevelKey: AVVideoProfileLevelH264High40
    ]
]

let audioSettings = [
  AVFormatIDKey: kAudioFormatMPEG4AAC,
  AVNumberOfChannelsKey: 1,
  AVSampleRateKey: 44100,
  AVEncoderBitRateKey: 96_000
]


protocol EpisodeUploaderDelegate: AnyObject {
  func didFail(with error: Error)
  func didFinishUploading(videoInfo: VideoInfo, callback: @escaping () -> Void)
}

final class EpisodeUploader: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  weak var delegate: EpisodeUploaderDelegate?

  let exporterService: VideoProcessingServiceProtocol = VideoProcessingService()

  let imagePickerController: UIImagePickerController = {
    let controller = UIImagePickerController()
    controller.sourceType = .photoLibrary
    controller.mediaTypes = ["public.movie"]
    controller.allowsEditing = false
    controller.videoExportPreset = AVAssetExportPreset1280x720

    return controller
  }()

  override init() {
    super.init()
    self.imagePickerController.delegate = self
  }

  private var presentingView: UIViewController?

  func exportVideo(presentingView: UIViewController) {
    self.presentingView = presentingView
    self.presentingView?.present(self.imagePickerController, animated: true, completion: nil)
  }

  func authorizeToAlbum(completion: @escaping (Bool) -> Void) {

    if PHPhotoLibrary.authorizationStatus() != .authorized {
      NSLog("Will request authorization")
      PHPhotoLibrary.requestAuthorization({ (status) in
        if status == .authorized {
          DispatchQueue.main.async {
            completion(true)
          }
        } else {
          DispatchQueue.main.async {
            completion(false)
          }
        }
      })

    } else {
      DispatchQueue.main.async {
        completion(true)
      }
    }
  }
  
  func getUniqueFileUrl() -> URL {
    let tempDirectory = NSTemporaryDirectory()
    let tempVideoName = "/\(UUID().uuidString)"
    let processedURL = URL(fileURLWithPath: tempDirectory.appending(tempVideoName).appending(".mp4"))
    return processedURL
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
    let tempDirectory = NSTemporaryDirectory()
    let tempVideoName = UUID().uuidString
    let processedURL = URL(fileURLWithPath: tempDirectory.appending(tempVideoName).appending(".mp4"))

    DispatchQueue(label: "video uploader queue").async {
      do {

        var processingParams = try VideoProcessingParameters(
          sourceURL: videoURL,
          outputURL: processedURL,
          targetFrameSize: CGSize(width: 600, height: 400),
          outputFileType: .mp4,
          audioSettings: audioSettings,
          videoSettings: videoSettings
        )!
        
        do {
          let fixedAspectRatio = try self.exporterService.changeAspectRatioIfNeeded(processingParameters: processingParams)
          if let error = fixedAspectRatio.error {
            throw error
          }
          processingParams.updateSourceUrl(fixedAspectRatio.inputParams.outputUrl)
          processingParams.updateOutputUrl(self.getUniqueFileUrl())
        } catch let aspectRatioProcessError {
          switch aspectRatioProcessError {
          case VideoAssetExportError.aspectRatioOk:
            break
          default:
            throw aspectRatioProcessError
          }
        }

        let output = try self.exporterService.processVideo(processingParameters: processingParams)
        if let error = output.error {
          throw error
        }
// uncomment these lines to save processed and cropped video in gallery
//                    DispatchQueue.main.async {
//                      //Call when finished
//                      PHPhotoLibrary.shared().performChanges({
//                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: output.inputParams.outputUrl)
//                      }) { saved, error in
//                        if saved {
//                          debugPrint("video has been saved to gallery")
//                        }
//                      }
//                    }

        try? FileManager.default.removeItem(at: processedURL)
        DispatchQueue.main.async {
          self.delegate?.didFinishUploading(videoInfo: result, callback: {
            picker.dismiss(animated: true, completion: nil)
          })
        }
      
      } catch let error {
        switch error {
        case VideoAssetExportError.nilVideoTrack:
          fallthrough
        case VideoAssetExportError.portraitVideoNotSupported:
          fallthrough
        default:
          try? FileManager.default.removeItem(at: processedURL)
          DispatchQueue.main.async {
            picker.dismiss(animated: true, completion: nil)
            self.delegate?.didFail(with: error)
          }
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
  }
  
}

```
