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
import AVFoundationExtensions
import SPMAssetExporter

open class VideoProcessingService: VideoProcessingServiceProtocol {

  public init() {

  }

  open func changeAspectRatioIfNeeded(processingParameters: VideoProcessingParameters) throws -> VideoProcessingOutput {
    let asset = AVAsset(url: processingParameters.sourceUrl)

    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      throw VideoAssetExportError.nilVideoTrack
    }
    if asset.orientation == .portrait || asset.orientation == .portraitUpsideDown {
      throw VideoAssetExportError.portraitVideoNotSupported
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
    let sourceRatio = naturalSize.width / naturalSize.height

    let targetRatio: CGFloat = 6/4
    if sourceRatio == targetRatio {
      throw VideoAssetExportError.aspectRatioOk
    } else {

      let targetWidth = targetRatio * naturalSize.width / sourceRatio

      let targetSize = CGSize(width: targetWidth, height: naturalSize.height)

      //create a video composition and preset some settings
      let  videoComposition = AVMutableVideoComposition(propertiesOf: asset)
      videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

      //here we are setting its render size
      videoComposition.renderSize = CGSize(width: targetSize.width, height: targetSize.height)
      //create a video instruction
      let instruction = AVMutableVideoCompositionInstruction()
      instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
      let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)


      let yratio: CGFloat = targetSize.height / naturalSize.height
      let postWidth: CGFloat = targetWidth
      let postHeight: CGFloat = naturalSize.height
      let transx: CGFloat = -(naturalSize.width - postWidth) / 2
      let transy: CGFloat = (targetSize.height - postHeight) / 2
      let matrix = CGAffineTransform(translationX: transx, y: transy / yratio)
      var transform = videoTrack.preferredTransform
      transform = transform.concatenating(matrix)
      transformer.setTransform(transform, at: CMTime.zero)

      instruction.layerInstructions = [transformer]
      videoComposition.instructions = [instruction]
      var output: VideoProcessingOutput = VideoProcessingOutput(inputParams: processingParameters)
      //Remove any prevouis videos at that path
      try? FileManager.default.removeItem(at: processingParameters.outputUrl)
      //Export
      let exporter = SDAVAssetExportSession(asset: asset)!
      exporter.outputFileType = processingParameters.outputFileType.rawValue
      exporter.outputURL = processingParameters.outputUrl
      exporter.videoSettings = processingParameters.videoSettings
      exporter.audioSettings = processingParameters.audioSettings
      exporter.videoComposition = videoComposition

      let dispatchGroup = DispatchGroup()
      dispatchGroup.enter()
      exporter.exportAsynchronously(completionHandler: {
        debugPrint(exporter.status)
        switch exporter.status {
        case .unknown:
          break
        case .waiting:
          break
        case .exporting:
          break
        case .failed:
          output.result = exporter.status
          output.error = exporter.error
          dispatchGroup.leave()
        case .completed:
          output.result = exporter.status
          output.error = exporter.error
          dispatchGroup.leave()
        case .cancelled:
          output.result = exporter.status
          output.error = exporter.error
          dispatchGroup.leave()
        @unknown default:
          output.result = exporter.status
          output.error = exporter.error
          dispatchGroup.leave()
        }

      })

      _ = dispatchGroup.wait(timeout: .distantFuture)
      return output
    }
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
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)

    //here we are setting its render size
    videoComposition.renderSize = CGSize(width: targetSize.width, height: targetSize.height)

    //create a video instruction
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: asset.duration)
    let transformer: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)


    let xratio: CGFloat = targetSize.width / naturalSize.width // 600 / 1080
    var transform = videoTrack.preferredTransform
    transform = transform.concatenating(CGAffineTransform(scaleX: xratio, y: xratio))
    transformer.setTransform(transform, at: CMTime.zero)

    instruction.layerInstructions = [transformer]
    videoComposition.instructions = [instruction]
    var output: VideoProcessingOutput = VideoProcessingOutput(inputParams: processingParameters)
    //Remove any prevouis videos at that path
    try? FileManager.default.removeItem(at: processingParameters.outputUrl)
    //Export
    let exporter = SDAVAssetExportSession(asset: asset)!
    exporter.outputFileType = processingParameters.outputFileType.rawValue
    exporter.outputURL = processingParameters.outputUrl
    exporter.videoSettings = [AVVideoCodecKey: AVVideoCodecType.h264,
                              AVVideoWidthKey: targetSize.width,
                              AVVideoHeightKey: targetSize.height,
                              AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 1024_000,
                                                                AVVideoProfileLevelKey: AVVideoProfileLevelH264High40]]
    exporter.audioSettings = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                              AVNumberOfChannelsKey: 1,
                              AVSampleRateKey: 44100,
                              AVEncoderBitRateKey: 96_000]
    exporter.videoComposition = videoComposition

    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()
    exporter.exportAsynchronously(completionHandler: {
      switch exporter.status {
      case .unknown:
        break
      case .waiting:
        break
      case .exporting:
        break
      case .failed:
        output.result = exporter.status
        output.error = exporter.error
        dispatchGroup.leave()
      case .completed:
        output.result = exporter.status
        output.error = exporter.error
        dispatchGroup.leave()
      case .cancelled:
        output.result = exporter.status
        output.error = exporter.error
        dispatchGroup.leave()
      @unknown default:
        output.result = exporter.status
        output.error = exporter.error
        dispatchGroup.leave()
      }
    })
    _ = dispatchGroup.wait(timeout: .distantFuture)
    return output
  }
}
