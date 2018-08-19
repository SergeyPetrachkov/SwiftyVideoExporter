//
//  VideoProcessingService.swift
//  PreUploadVideoProcessor
//
//  Created by Sergey Petrachkov on 19/08/2018.
//  Copyright © 2018 Sergey Petrachkov. All rights reserved.
//

import Foundation
import AVKit
import UIKit

open class VideoProcessingService: VideoProcessingServiceProtocol {
  public init() {
    
  }
  open func processVideo(processingParameters: VideoProcessingParameters) throws -> VideoProcessingOutput {
    let asset = AVAsset(url: processingParameters.sourceUrl)
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      throw VideoAssetExportError.nilVideoTrack
    }
    
    let naturalSize = videoTrack.naturalSize
    
    // I have not figured out how to deal with portrait videos yet
    if naturalSize.width < naturalSize.height {
      throw VideoAssetExportError.portraitVideoNotSupported
    }
    
    let targetSize = processingParameters.targetFrameSize
    if targetSize.width < targetSize.height {
      throw VideoAssetExportError.portraitVideoNotSupported
    }
    
    //create a video composition and preset some settings
    let  videoComposition = AVMutableVideoComposition(propertiesOf: asset)
    videoComposition.frameDuration = CMTimeMake(1, 30)
    
    //here we are setting its render size
    videoComposition.renderSize = CGSize(width: targetSize.width, height: targetSize.height)
    //create a video instruction
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30))
    let transformer: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    
    
    let ratio: CGFloat = targetSize.width / targetSize.height
    let xratio: CGFloat = targetSize.width / naturalSize.width
    let yratio: CGFloat = targetSize.height / naturalSize.height
    let postWidth: CGFloat = naturalSize.width * ratio
    let postHeight: CGFloat = naturalSize.height * ratio
    let transx: CGFloat = (targetSize.width - postWidth) / 2
    let transy: CGFloat = (targetSize.height - postHeight) / 2
    let matrix = CGAffineTransform(translationX: transx / xratio, y: transy / yratio)
    var transform = videoTrack.preferredTransform
    transform = transform.concatenating(matrix)
    transform = transform.concatenating(CGAffineTransform(scaleX: ratio, y: ratio))
    transformer.setTransform(transform, at: kCMTimeZero)
    
    instruction.layerInstructions = [transformer]
    videoComposition.instructions = [instruction]
    var output: VideoProcessingOutput = VideoProcessingOutput(inputParams: processingParameters)
    //Remove any prevouis videos at that path
    try? FileManager.default.removeItem(at: processingParameters.outputUrl)
    //Export
    let exporter = AVAssetExportSession(asset: asset,
                                        presetName: AVAssetExportPresetHighestQuality)!
    exporter.videoComposition = videoComposition
    exporter.outputURL = processingParameters.outputUrl
    exporter.outputFileType = processingParameters.outputFileType
    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    exporter.exportAsynchronously(completionHandler: {
      switch exporter.status {
      case .completed:
        fallthrough
      default:
        output.result = exporter.status
        output.error = exporter.error
      }
      dispatchGroup.leave()
    })
    
    _ = dispatchGroup.wait(timeout: .distantFuture)
    return output
  }
}
