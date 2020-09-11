//
//  VideoProcessingParameters.swift
//  PreUploadVideoProcessor
//
//  Created by Sergey Petrachkov on 19/08/2018.
//  Copyright © 2018 Sergey Petrachkov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public struct VideoProcessingParameters {
  public let sourceUrl: URL
  public let outputUrl: URL
  public let targetFrameSize: CGSize
  public let outputFileType: AVFileType
  public let audioSettings: [String: Any]
  public let videoSettings: [String: Any]
  
  public init?(sourceURL: URL,
               outputURL: URL,
               targetFrameSize: CGSize,
               outputFileType: AVFileType,
               audioSettings: [String: Any],
               videoSettings: [String: Any]) throws {
    if targetFrameSize.width < targetFrameSize.height {
      throw VideoAssetExportError.portraitVideoNotSupported
    }
    self.sourceUrl = sourceURL
    self.outputUrl = outputURL
    self.targetFrameSize = targetFrameSize
    self.outputFileType = outputFileType
    self.audioSettings = audioSettings
    self.videoSettings = videoSettings
  }
}
