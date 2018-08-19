//
//  VideoProcessingOutput.swift
//  PreUploadVideoProcessor
//
//  Created by Sergey Petrachkov on 19/08/2018.
//  Copyright © 2018 Sergey Petrachkov. All rights reserved.
//

import Foundation
import AVKit

public struct VideoProcessingOutput {
  public let inputParams: VideoProcessingParameters
  public var result: AVAssetExportSessionStatus
  public var error: Error?
  
  public init(inputParams: VideoProcessingParameters) {
    self.inputParams = inputParams
    self.result = .unknown
    self.error = nil
  }
}
