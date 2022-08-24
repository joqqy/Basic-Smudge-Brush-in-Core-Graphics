//
//  ImageTools.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import Foundation
import UIKit

struct ImageTools {
    
    /// Converts an UIImage to grayscale and returns a cgImage
    /// We need this if we want to use the image as a mask, since the mask needs to be in DeviceGray color space
    /// This will create a DeviceGray or kCGColorSpaceModelMonochrome color space
    static func convertToGrayScale(image: UIImage) -> CGImage? {
        
        // Geometry
        let imageRect: CGRect = CGRect(origin: CGPoint.zero, size: image.size)
        
        // Image settings
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context: CGContext? = CGContext(data: nil,
                                            width: Int(imageRect.width),
                                            height: Int(imageRect.height),
                                            bitsPerComponent: 8,
                                            bytesPerRow: 0,
                                            space: colorSpace,
                                            bitmapInfo: bitmapInfo.rawValue)
        
        // Draw the image into the context
        context?.draw(image.cgImage!, in: imageRect)
        
        // Grab the image from the context
        let imageRef: CGImage? = context!.makeImage()
        
        // If we want to get it backas an uiimage
        //let newImage = UIImage(cgImage: imageRef)
        
        return imageRef
    }
    
    /// Warning, while this will create a gray image, IT WILL NOT CREATE DeviceGray color.
    /// Result of this is kCGColorSpaceDeviceRGB
    static func ciConvertToGrayScale(image: UIImage, imageStyle: String, context: CIContext) -> UIImage? {
        
        let currentFilter = CIFilter(name: imageStyle)
        
        if let filter: CIFilter = currentFilter {
            
            filter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
            
            if let output: CIImage = filter.outputImage,
               let cgImg: CGImage = context.createCGImage(output, from: output.extent) {
                
                let processedImage: UIImage = UIImage(cgImage: cgImg)
                return processedImage
            }
        }
        return nil
    }
}
