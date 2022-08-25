//
//  CanvasView.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import Foundation
import UIKit

struct Sample {
    
    var pos: CGPoint = .zero
}

class CanvaView: UIView {
    
    /// Will receive continues pixel data from CanvasView backing layer
    var imageView: UIImageView!
    
    var image: UIImage?
    
    var toolSegmentIndex: Int = 0 // default is 0 = paint
    
    var touchSamples: [Sample] = []
    
    override func didMoveToSuperview() {
        
        self.backgroundColor = .lightGray

        //drawCheckerBoard() // This draws a checkerboard into UIImage, and we set that image to imageView.image and then add the imageView as a subview
        //layer.setNeedsDisplay() // This calls the draw(in) layer, and draws whatever is implemented there
        
        self.image = UIImage(named: "tiger")
        
        // To position the UIImageView if we use it
        let pos: CGPoint = CGPoint(x: self.center.x, y: self.center.y)
        //drawMask(at: pos)
        //drawMask_With_CIImage(at: pos)
    }
    
    // Whenver we call layer.setNeedsDisplay(), this is called
    // This is part of the CALayerDelegate
    /*
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        
        ctx.setFillColor(UIColor.black.cgColor)
        
        for row in 0 ..< 10 {
            for col in 0 ..< 10 {
                if (row + col) % 2 == 0 {
                    ctx.fill(CGRect(x: col * 64, y: row * 64, width: 64, height: 64))
                }
            }
        }
    }
     */
    
    /*
    // Overriding draw(rect:)
    override func draw(_ rect: CGRect) {

        if let ctx: CGContext = UIGraphicsGetCurrentContext() {

            if let cg: CGImage = self.image?.cgImage,
               let size: CGSize = self.image?.size {

                // If the mask is an image, then white areas are opaque, and black areas are transparent
                // If the mas is a mask, white areas are transparent and black areas opaque.
                // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101

                if let mask = UIImage(named: "mask_1_S")?.cgImage {
                    if let masked = cg.masking(mask) {
                        
                        // Note that in Swift, CGImageRelease is deprecated and ARC is now managing it
                        // So no need to realese the mask in Swift, it is all handled by ARC

                        let rect: CGRect = CGRect(origin: .zero, size: size)

                        // Save context state
                        ctx.saveGState()

                        // Flip the context so that the coordinates match the default coordinate system of UIKit
                        // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
                        ctx.translateBy(x: 0, y: size.height)
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
    
    var brushSize: CGSize = CGSize(width: 256, height: 256)
    
    override func draw(_ rect: CGRect) {

        if let ctx: CGContext = UIGraphicsGetCurrentContext() {
            
            switch self.toolSegmentIndex
            {
            case 0:
                
                // Note, this only draw black squares, meaning the squares that contain white are really just transparent
                // To draw white squares too uncomment the commented code
                for row in 0 ..< 10 {
                    for col in 0 ..< 10 {
                        
                        if (row + col) % 2 == 0 {
                            
                            ctx.setFillColor(UIColor.black.cgColor)
                            ctx.fill(CGRect(x: col * 64, y: row * 64, width: 64, height: 64))
                            
                        } /*else {
                            
                            ctx.setFillColor(UIColor.white.cgColor)
                            ctx.fill(CGRect(x: col * 64, y: row * 64, width: 64, height: 64))
                        }*/
                    }
                }
                
            case 1:
                
                for row in 0 ..< 10 {
                    for col in 0 ..< 10 {
                        
                        if (row + col) % 2 == 0 {
                            
                            ctx.setFillColor(UIColor.black.cgColor)
                            ctx.fill(CGRect(x: col * 64,
                                            y: row * 64,
                                            width: 64,
                                            height: 64))
                            
                        } else {
                            
                            ctx.setFillColor(UIColor.white.cgColor)
                            ctx.fill(CGRect(x: col * 64,
                                            y: row * 64,
                                            width: 64,
                                            height: 64))
                        }
                    }
                }
                
                for touchSample in self.touchSamples {

                    // If the mask is an image, then white areas are opaque, and black areas are transparent
                    // If the mas is a mask, white areas are transparent and black areas opaque.
                    // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101
                    
                    let pos: CGPoint = CGPoint(x: touchSample.pos.x * UIScreen.main.scale - brushSize.width/2.0,
                                               y: touchSample.pos.y * UIScreen.main.scale  - brushSize.height/2.0)
                    let rect: CGRect = CGRect(origin: pos, size: brushSize)


//                    // Flip the context so that the coordinates match the default coordinate system of UIKit
//                    // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
//                    ctx.translateBy(x: 0, y: CGFloat(ctx.height))
//                    ctx.scaleBy(x: 1, y: -1)
                    
                    //let cgCopy = UIGraphicsGetImageFromCurrentImageContext()?.cgImage?.cropping(to: rect) // This fails
                    let cgCopy: CGImage? = ctx.makeImage()?.cropping(to: rect) // This works, copies the pixels of the current context, however, at this point, there is nothing in the context(it has been cleared!!!) how do we preserve the context???
                    
                    
                    if let cgCopy: CGImage = cgCopy,
                       let mask: CGImage = UIImage(named: "mask_1_S")?.cgImage {
                        
                        if let masked: CGImage = cgCopy.masking(mask) {
                            
                            // Note that in Swift, CGImageRelease is deprecated and ARC is now managing it
                            // So no need to realese the mask in Swift, it is all handled by ARC

                            let rect: CGRect = CGRect(origin: .zero, size: brushSize)

                            // Save context state
                            ctx.saveGState()
                            
                            // Flip the context so that the coordinates match the default coordinate system of UIKit
                            // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
                            ctx.translateBy(x: 0, y: self.bounds.size.height)
                            ctx.scaleBy(x: 1, y: -1)

                            ctx.translateBy(x: touchSample.pos.x - brushSize.width/2.0,
                                            y: self.bounds.size.height - touchSample.pos.y - brushSize.height/2.0)

                            // Draw
                            ctx.setAlpha(1.0)
                            ctx.setBlendMode(.normal)
                            ctx.draw(masked, in: rect)
                            
                            // Restore context state
                            ctx.restoreGState()
                        }
                    }
                }
                
            default:
                break
            }
            
        }
    }
    
    /*
    // Overriding draw(rect:), this draws a checkerboard pattern
    override func draw(_ rect: CGRect) {
        
        if let ctx = UIGraphicsGetCurrentContext() {
            
            ctx.setFillColor(UIColor.black.cgColor)
            
            for row in 0 ..< 10 {
                for col in 0 ..< 10 {
                    if (row + col) % 2 == 0 {
                        ctx.fill(CGRect(x: col * 64, y: row * 64, width: 64, height: 64))
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
            view.tag = 0xDEADBEEF
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch: UITouch = touches.first else { return }
        
        addSample(touch)
        self.setNeedsDisplay()
        
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch: UITouch = touches.first else { return }
        
        addSample(touch)
        self.setNeedsDisplay()
        
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchSamples.removeAll()
    }
    
    func addSample(_ touch: UITouch) -> Void {
        
        var sample = Sample()
        sample.pos = touch.location(in: self)
        
        self.touchSamples.append(sample)
    }
}

extension CanvaView {
    
    func drawCheckerBoard() {
        
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        
        let img: UIImage = renderer.image { ctx in
            
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
