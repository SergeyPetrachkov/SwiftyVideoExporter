//
//  VideoProcessingServiceProtocol.swift
//  PreUploadVideoProcessor
//
//  Created by Sergey Petrachkov on 19/08/2018.
//  Copyright © 2018 Sergey Petrachkov. All rights reserved.
//

import Foundation

public protocol VideoProcessingServiceProtocol: class {
  func processVideo(processingParameters: VideoProcessingParameters) throws -> VideoProcessingOutput
}
