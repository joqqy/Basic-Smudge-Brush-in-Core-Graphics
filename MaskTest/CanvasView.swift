//
//  CanvasView.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import Foundation
import UIKit

struct Sample {
    
    var previousPos: CGPoint = .zero
    var pos: CGPoint = .zero
    var force: CGFloat = 1.0
}

class CanvasView: UIView {
    
    /// Will receive continues pixel data from CanvasView backing layer
    var imageView: UIImageView!
    
    /// We draw into this and then this draws itself into the backing layer
    var image: UIImage?
    
    var toolSegmentIndex: Int = 0
    
    /// Collect the touch information in here
    var touchSamples: [Sample] = []
    /// Spacing for line segments
    var kBrushPixelStep: CGFloat = 1.0
    var doInterpolate: Bool = false // :false, true is very slow
    
    var brushSize: CGSize = CGSize(width: 30, height: 30)
    
    override func didMoveToSuperview() {

        self.backgroundColor = .lightGray

        //drawCheckerBoard() // This draws a checkerboard into UIImage, and we set that image to imageView.image and then add the imageView as a subview
        //layer.setNeedsDisplay() // This calls the draw(in) layer, and draws whatever is implemented there
        
        self.image = UIImage(named: "tiger")
        
        // To position the UIImageView if we use it
        //let pos: CGPoint = CGPoint(x: self.center.x, y: self.center.y)
        //drawMask(at: pos)
        //drawMask_With_CIImage(at: pos)
        
        // Double tap to clear the image view
        let gestureTap = UITapGestureRecognizer(target: self, action: #selector(restoreImage))
        gestureTap.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
        gestureTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(gestureTap)
    }
    
    /// On double tap, restore the image
    @objc func restoreImage() {
        
        self.image = UIImage(named: "tiger")
        self.touchSamples.removeAll()
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
    
    /*
    override func draw(_ rect: CGRect) {

        if let ctx: CGContext = UIGraphicsGetCurrentContext() {
            
            switch self.toolSegmentIndex
            {
            case 0:
                
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
    */
    
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
    
    /// This ensures the UIImage keeps updating the canvasView's backing layer by drawing itself into it at every change
    /// When we call setNeedsDisplay, this draw() is called, which draws the uiimage we have been painting into, into the views screen buffer.
    /// So the uiimage drawingImage serves as our backbuffer.
    /// UIImages knows how to draw themselves into the context, which is quite convenient. All we have to do is calle UIImage.draw(in: rect).
    override func draw(_ rect: CGRect) {

        // UIImages knows how to draw themselves into the context, which is quite convenient. All we have to do is calle UIImage.draw(in: rect).
        self.image?.draw(in: rect)
    }
    
    func smudge() {
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size)

        self.image = renderer.image { context in
            
            // Draw current state of the image into the context
            self.image?.draw(in: bounds)
            
            let ctx: CGContext = context.cgContext
            
            for touchSample in self.touchSamples {
                
                let brushSize = CGSize(width: brushSize.width * touchSample.force,
                                       height: brushSize.height * touchSample.force)

                // If the mask is an image, then white areas are opaque, and black areas are transparent
                // If the mas is a mask, white areas are transparent and black areas opaque.
                // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101
                
                //------------------------------------------------------------------------
                // Calculate the rect we want to copy from the current context (we will use this rect for CGContext.makeImage().cropping8to: rect)
                // The principal method is we copy the context from the previous touch pos, then copy that over to the current touch pos(later down as we draw it on the context)
                //------------------------------------------------------------------------
                let radiusX = brushSize.width/2.0
                let radiusY = brushSize.height/2.0
                let previousPos: CGPoint = CGPoint(x: touchSample.previousPos.x * UIScreen.main.scale - radiusX,
                                                   y: touchSample.previousPos.y * UIScreen.main.scale - radiusY)
                let rect: CGRect = CGRect(origin: previousPos, size: brushSize)
                
                //------------------------------------------------------------------------
                // Copy an image from the current context, we get a CGImage. Crop it to desired size and location
                //------------------------------------------------------------------------
                
                //let cgCopy = UIGraphicsGetImageFromCurrentImageContext()?.cgImage?.cropping(to: rect) // This fails
                let cgCopy: CGImage? = ctx.makeImage()?.cropping(to: rect) // This works, copies the pixels of the current context, however, at this point, there is nothing in the context(it has been cleared!!!) how do we preserve the context???
                
                //------------------------------------------------------------------------
                // Apply a mask to the copied image
                //------------------------------------------------------------------------
                if let cgCopy: CGImage = cgCopy,
                   let mask: CGImage = UIImage(named: "mask_1_S")?.cgImage,
                   let masked: CGImage = cgCopy.masking(mask) {
                        
                    // Note that in Swift, CGImageRelease is deprecated and ARC is now managing it
                    // So no need to realese the mask in Swift, it is all handled by ARC


                    //------------------------------------------------------------------------
                    // Save the context state and all subsuquent changes
                    //------------------------------------------------------------------------
                    ctx.saveGState()
                    
                    
                    
                    //------------------------------------------------------------------------
                    // Transform the coordinates of the context
                    //------------------------------------------------------------------------
                    // Flip the context so that the coordinates match the default coordinate system of UIKit
                    // https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/HandlingImages/Images.html#//apple_ref/doc/uid/TP40010156-CH13-SW1
                    ctx.translateBy(x: 0, y: self.bounds.size.height)
                    ctx.scaleBy(x: 1, y: -1)

                    // Transform the context with respect to the touch position
                    ctx.translateBy(x: touchSample.pos.x - brushSize.width/2.0,
                                    y: self.bounds.size.height - touchSample.pos.y - brushSize.height/2.0)

                    
                    
                    
                    //------------------------------------------------------------------------
                    // Set some drawing settings for the context
                    //------------------------------------------------------------------------
                    // Draw
                    let alphaConstantFactor: CGFloat = 0.1
                    ctx.setAlpha(min(touchSample.force * alphaConstantFactor, 1.0))
                    ctx.setBlendMode(.normal)
                    //------------------------------------------------------------------------
                    // Draw into the context
                    //------------------------------------------------------------------------
                    // Set size of the copied image we want to draw into the contex
                    let rect: CGRect = CGRect(origin: .zero, size: brushSize)
                    // Draw
                    ctx.draw(masked, in: rect)
                    
                    
                    
                    
                    //------------------------------------------------------------------------
                    // Restore the context
                    //------------------------------------------------------------------------
                    ctx.restoreGState()
                }
            }
            
            self.setNeedsDisplay()
        }
    }
    
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
        // Call the drawing
        self.smudge()
        
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch: UITouch = touches.first else { return }
        
        addSample(touch)
        // Call the drawing
        self.smudge()
        
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
        
        if self.doInterpolate {
            
            var spacingCount: Int = 0
            
            if self.touchSamples.count > 1 {
                var interpolatedLine: [Sample] = [Sample]()
                // Do a linear interpolation between a pair of points, to fill the gap with additional points with kBrushPixelStep spacing
                for i in 0 ..< self.touchSamples.count - 1 {
                    
                    let prev0: CGPoint = self.touchSamples[i].previousPos
                    let prev1: CGPoint = self.touchSamples[i + 1].previousPos
                    
                    let p0: CGPoint = self.touchSamples[i].pos
                    let p1: CGPoint = self.touchSamples[i + 1].pos
                    
                    let force0: CGFloat = self.touchSamples[i].force
                    let force1: CGFloat = self.touchSamples[i + 1].force
                    // Interpolate force
                    let force = (force0 + force1) / 2.0
                    
                    // How many points do we need to distribute between each pair of points to satisfy the option to get n xpixes between each point
                    spacingCount = max(Int(ceil(CGPoint.length(p0 - p1) / self.kBrushPixelStep)), 1)

                    // Interpolate pos linearly between the two points
                    for n in 0 ..< spacingCount {
                        
                        let s: CGFloat = (CGFloat(n) / CGFloat(spacingCount))
                        let prevPos: CGPoint = s * (prev1 - prev0) + prev0
                        let pos: CGPoint = s * (p1 - p0) + p0
                        
                        var sample = Sample()
                        
                        sample.previousPos = prevPos
                        sample.pos = pos
                        sample.force = force
                        
                        interpolatedLine.append(sample)
                    }
                }
                
                self.touchSamples = interpolatedLine
            }
        }
        
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchSamples.removeAll()
    }
    func addSample(_ touch: UITouch) -> Void {
        
        var sample = Sample()
        
        sample.previousPos = touch.previousLocation(in: self)
        sample.pos = touch.location(in: self)
        
        if touch.force > 0 {
            sample.force = touch.force
        }
        
        self.touchSamples.append(sample)
    }
}

extension CanvasView {
    
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
