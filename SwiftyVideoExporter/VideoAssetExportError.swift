//
//  VideoAssetExportError.swift
//  PreUploadVideoProcessor
//
//  Created by Sergey Petrachkov on 19/08/2018.
//  Copyright © 2018 Sergey Petrachkov. All rights reserved.
//

import Foundation

public enum VideoAssetExportError: Error {
  case nilVideoTrack
  case portraitVideoNotSupported
}
