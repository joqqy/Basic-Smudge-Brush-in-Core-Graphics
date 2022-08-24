//
//  CanvasView.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import Foundation
import UIKit

class CanvaView: UIView {
    
    /// Will receive continues pixel data from CanvasView backing layer
    var imageView: UIImageView!
    
    var image: UIImage?
    
    override func didMoveToSuperview() {
        
        self.backgroundColor = .white
        
        drawCheckerBoard()
        
        self.image = UIImage(named: "tiger")
        
        // To position the UIImageView if we use it
        let pos: CGPoint = CGPoint(x: self.center.x, y: self.center.y)
        //drawMask(at: pos)
        drawMask_With_CIImage(at: pos)
    }
    
    /*
    // Overriding draw(rect:)
    override func draw(_ rect: CGRect) {

        if let ctx: CGContext = UIGraphicsGetCurrentContext() {

            if let cg: CGImage = self.image?.cgImage,
               let size: CGSize = self.image?.size {

                // If the mask is an image, then white areas are opaque, and black areas are transparent
                // If the mas is a mask, white areas are transparent and black areas opaque.
                // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101

                if let mask = UIImage(named: "tigermask_1_S")?.cgImage {
                    if let masked = cg.masking(mask) {
                        
                        // Note that in Swift, CGImageRelease is deprecated and ARC is now managing it
                        // So no need to realese the mask in Swift, it is all handled by ARC

                        let rect: CGRect = CGRect(origin: .zero, size: size)

                        // Save context state
                        ctx.saveGState()

                        // Flip the context so that the coordinates match the default coordinate system of UIKit
                        // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
                        ctx.translateBy(x: 0, y: size.width)
                        ctx.scaleBy(x: 1, y: -1)

                        // Draw
                        ctx.draw(masked, in: rect)

                        // Restore context state
                        ctx.restoreGState()
                    }
                }
            }
        }
    }
    */
    
    /// We can do this as well
    /// - Parameters:
    ///     - pos: Position of the UIImageView
    func drawMask(at pos: CGPoint) {
        
        if let cg: CGImage = self.image?.cgImage,
           let size: CGSize = self.image?.size {
            
            let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: size)
            
            let img: UIImage = renderer.image { ctx in
                
                if let mask: CGImage = UIImage(named: "tigermask_1_S")?.cgImage {
                    if let masked: CGImage = cg.masking(mask) {
                        
                        // Note that in Swift, CGImageRelease is deprecated and ARC is now managing it
                        // So no need to realese the mask in Swift, it is all handled by ARC
                        
                        let rect: CGRect = CGRect(origin: .zero, size: size)
         
                        // Save context state
                        ctx.cgContext.saveGState()
                        
                        // Flip the context so that the coordinates match the default coordinate system of UIKit
                        // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
                        ctx.cgContext.translateBy(x: 0, y: size.width)
                        ctx.cgContext.scaleBy(x: 1, y: -1)
                        
                        // Draw
                        ctx.cgContext.draw(masked, in: rect)
                        
                        // Restore context state
                        ctx.cgContext.restoreGState()
                    }
                }
            }
            
            self.image = img
            
            let view: UIImageView = UIImageView(image: self.image)
            view.center = pos
            
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(view)
        }
    }
    
    let ciContex = CIContext(options: [CIContextOption.useSoftwareRenderer : false])
    /// We can do this as well
    /// - Parameters:
    ///     - pos: Position of the UIImageView
    func drawMask_With_CIImage(at pos: CGPoint) {
        
        if let cg: CGImage = self.image?.cgImage,
           let size: CGSize = self.image?.size {
            
            // Create a brush CIFilter radial gradient, we will use this as a mask
            let brushFilter: CIFilter? = CIFilter(name: "CIRadialGradient",
                                                  parameters:
                                                   [kCIInputCenterKey : CIVector(x: size.width/2,
                                                                                 y: size.height/2),
                                                    "inputRadius0" : 0,
                                                    "inputRadius1" : size.width/2,
                                                    "inputColor0" : CIColor(red: 1, green: 1, blue: 1, alpha: 1.0),
                                                    "inputColor1" : CIColor(red: 0, green: 0, blue: 0, alpha: 1.0)])
            
            let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: size)
            
            let img: UIImage = renderer.image { ctx in
                
                // Fetch the CIImage from the brush filter
                var brushImage: CIImage? = brushFilter?.outputImage
                // Crop the CIImage to desired size
                brushImage = brushImage?.cropped(to: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                
                if let input: CIImage = brushImage,
                   let mask: CGImage = self.ciContex.createCGImage(input, from: input.extent, format: .ABGR8, colorSpace: nil/*CGColorSpace(name: CGColorSpace.linearSRGB)*/),
                   let maskConvert = ImageTools.convertToGrayScale(image: UIImage(cgImage: mask)), // Unless we convert the cgImage that we retreive from CIImage, it doesn't work, that is why we do this
                   let masked: CGImage = cg.masking(maskConvert) {

                    // Note that in Swift, CGImageRelease is deprecated and ARC is now managing it
                    // So no need to realese the mask in Swift, it is all handled by ARC

                    let rect: CGRect = CGRect(origin: .zero, size: size)

                    // Save context state
                    ctx.cgContext.saveGState()

                    // Flip the context so that the coordinates match the default coordinate system of UIKit
                    // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
                    ctx.cgContext.translateBy(x: 0, y: size.width)
                    ctx.cgContext.scaleBy(x: 1, y: -1)

                    // Draw
                    ctx.cgContext.draw(masked, in: rect)

                    // Restore context state
                    ctx.cgContext.restoreGState()
                }
            }
            
            self.image = img
            
            let view: UIImageView = UIImageView(image: self.image)
            view.tag = 0xDEADBEEF
            view.center = pos
            
            //self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(view)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch: UITouch = touches.first else { return }
        
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
    }
}

extension CanvaView {
    
    func drawCheckerBoard() {
        
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        
        let img = renderer.image { ctx in
            
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            
            for row in 0 ..< 10 {
                for col in 0 ..< 10 {
                    if (row + col) % 2 == 0 {
                        ctx.cgContext.fill(CGRect(x: col * 64, y: row * 64, width: 64, height: 64))
                    }
                }
            }
        }
        
        self.imageView = UIImageView(frame: self.bounds)
        self.imageView.image = img
        self.addSubview(self.imageView)
    }
}
