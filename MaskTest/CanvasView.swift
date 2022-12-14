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
    
    struct ImageNames {
                
        static let brush1: String = "brush1"
        static let brush1_inv: String = "brush1_inv"
        static let graphite1: String = "graphitePattern"
        static let roundSoft1: String = "roundSoft1"
        static let colorBar: String = "colorbar"
        static let tiger: String = "tiger"
        static let mask_1_S: String = "mask_1_S"
        static let mask_1_S_v2: String = "mask_1_S_v2"
        static let mask_1_S_v3: String = "mask_1_S_v3"
        static let mask_1_S_v4: String = "mask_1_S_v4"
        static let mask_1_S_v5: String = "mask_1_S_v5"
        static let mask_1_S_v6: String = "mask_1_S_v6"
        static let mask: String = "mask_S"
    }
    
    /// Will receive continues pixel data from CanvasView backing layer
//    var imageView: UIImageView!
    var outlineView: UIImageView!
    var currentImageName: String = ImageNames.colorBar
    
    /// We draw into this and then this draws itself into the backing layer
    var canvas: UIImage?
    var brushImage: UIImage?
    var brushColorCanGetDirty: Bool = true
    
    var toolSegmentIndex: Int = 0
    
    /// Collect the touch information in here
    var touchSamples: [Sample] = []
    /// Spacing for line segments
    var smudgeSpacing: CGFloat = 5.0 // Should really be = 1.0, but values < ~10 are too slow on Core Graphics/Quartz. We set it to 5 here, which is too slow for production.
    var doInterpolate: Bool = true // :false, true is very slow
    
    var brushSize: CGSize = CGSize(width: 60, height: 60)
    
    override func didMoveToSuperview() {

        self.backgroundColor = .lightGray
        
        self.layer.drawsAsynchronously = true

        //drawCheckerBoard() // This draws a checkerboard into UIImage, and we set that image to imageView.image and then add the imageView as a subview
        //layer.setNeedsDisplay() // This calls the draw(in) layer, and draws whatever is implemented there
        
        // Starting painting image
        self.canvas = UIImage(named: currentImageName)
        
        // Brush image for painting tool
        self.brushImage = UIImage(named: ImageNames.brush1)?.withRenderingMode(.alwaysTemplate)
        self.brushImage = self.brushImage?.withTintColor(.red)
                
        // We can scale the image by setting the rect appropriately instead in the context.draw() instead
        
        // For now though, this is the only way to set the color for the brushimage, not sue why tintcolor does not work unless we do this below
         
        // Scale the uiimage
        // Also, for some reason, color works well when we do a rescale, while color in the above does not work, very weird.
        let image: UIImage? = self.brushImage
        let scaledImageSize: CGSize = CGSize(width: brushSize.width, height: brushSize.height)
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: scaledImageSize)
        let scaledImage: UIImage = renderer.image { _ in
            image?.draw(in: CGRect(origin: .zero, size: scaledImageSize))
        }
        self.brushImage = scaledImage
        
        // To position the UIImageView if we use it
        //let pos: CGPoint = CGPoint(x: self.center.x, y: self.center.y)
        //drawMask(at: pos)
        //drawMask_With_CIImage(at: pos)
        
        // Double tap to clear the image view
        let gestureTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(restoreImage))
        gestureTap.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
        gestureTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(gestureTap)
        
        self.createBrushOutline()
    }
    
    func createBrushOutline() {
        
        self.outlineView = UIImageView(frame: CGRect(origin: .zero, size: brushSize))
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: self.outlineView.bounds.size)
        let img: UIImage = renderer.image { context in
            
            let ctx: CGContext = context.cgContext
            
            ctx.setStrokeColor(UIColor.lightGray.cgColor)
            ctx.setLineWidth(1)
            
            ctx.setAlpha(0.5)
            ctx.setBlendMode(.overlay)
            
            let rect = CGRect(origin: .zero, size: brushSize).insetBy(dx: 5, dy: 5)
            ctx.addEllipse(in: rect)
            ctx.drawPath(using: .stroke)
        }
        self.outlineView.image = img
    }
    
    /// On double tap, restore the image
    @objc func restoreImage() {
        
        self.canvas = UIImage(named: currentImageName)
        self.touchSamples.removeAll()
        self.setNeedsDisplay()
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
        
        // At this point, we have drawn our brush strokes into the uiimage
        // So we want to draw it into the view's layer

        // UIImages knows how to draw themselves into the context, which is quite convenient. All we have to do is call UIImage.draw(in: rect).
        self.canvas?.draw(in: rect)
    }
    
    func paint() {
        
        guard self.touchSamples.count > 0 else { return }
        
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: bounds.size)

        self.canvas = renderer.image { context in
            
            // Draw current state of the image into the context, because UIKit/CoreGraphics clears the context before drawing.
            // So we need to draw the latest canvas into the context to draw over.
            self.canvas?.draw(in: bounds)
            
            let ctx: CGContext = context.cgContext
            
            guard let first: Sample = touchSamples.first else { return }
            var unionRect: CGRect = CGRect(x: first.pos.x * UIScreen.main.scale,
                                           y: first.pos.y * UIScreen.main.scale,
                                           width: 1,
                                           height: 1)

            
//            for touchSample in self.touchSamples {
            for i in 1 ..< self.touchSamples.count {
                
                let touchSample = self.touchSamples[i]
                
                //------------------------------------------------------------------------
                // Apply a mask to the copied image
                //------------------------------------------------------------------------
                if let brush: CGImage = self.brushImage?.cgImage {
                        
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
//                    ctx.translateBy(x: 0, y: self.bounds.size.height)
//                    ctx.scaleBy(x: 1, y: -1)

                    // Transform the context with respect to the touch position
                    ctx.translateBy(x: touchSample.pos.x - brushSize.width/2.0,
                                    y: touchSample.pos.y - brushSize.height/2.0)

                    
                    unionRect = unionRect.union(CGRect(x: touchSample.pos.x - brushSize.width/2.0,
                                                       y: touchSample.pos.y - brushSize.height/2.0,
                                                       width: brushSize.width,
                                                       height: brushSize.height))
                    
                    //------------------------------------------------------------------------
                    // Set some drawing settings for the context
                    //------------------------------------------------------------------------
                    // Draw
                    let alphaConstantFactor: CGFloat = 0.1
                    ctx.setAlpha(touchSample.force * alphaConstantFactor)
                    ctx.setBlendMode(.normal)
                    //------------------------------------------------------------------------
                    // Draw into the context
                    //------------------------------------------------------------------------
                    // Set size of the copied image we want to draw into the contex
                    let rect: CGRect = CGRect(origin: .zero, size: brushSize)
                    // Draw
                    ctx.draw(brush, in: rect)
                    
                    /*
                    ctx.setStrokeColor(UIColor.lightGray.cgColor)
                    ctx.setLineWidth(2)
                    ctx.addEllipse(in: rect)
                    ctx.drawPath(using: .stroke)
                    */
                    
                    //------------------------------------------------------------------------
                    // Restore the context
                    //------------------------------------------------------------------------
                    ctx.restoreGState()
                }
            }
            
            self.setNeedsDisplay(unionRect)
        }
    }
    func smudge() {
        
        guard self.touchSamples.count > 0 else { return }
        
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: bounds.size)

        self.canvas = renderer.image { context in
            
            // Draw current state of the image into the context, because UIKit/CoreGraphics clears the context before drawing.
            // So we need to draw the latest canvas into the context to draw over.
            self.canvas?.draw(in: bounds)
            
            let ctx: CGContext = context.cgContext
            
            // Inside the point loop, we will continuously add rects, for a final rect encompassing all points, for the setneedsdisplay(rect) call at the end
            
            guard let first: Sample = touchSamples.first else { return }
            // Start of the unionRect at the first touch position rect (then later this unionrect will be expanded as needed starting from this starting rect).
            var unionRect: CGRect = CGRect(x: first.previousPos.x,
                                           y: first.previousPos.y,
                                           width: brushSize.width,
                                           height: brushSize.height)
            
//            for touchSample in self.touchSamples {
            
            for i in 1 ..< self.touchSamples.count {
                
                let touchSample: Sample = self.touchSamples[i]
                
                let brushSize: CGSize = CGSize(width: brushSize.width, height: brushSize.height)

                // If the mask is an image, then white areas are opaque, and black areas are transparent
                // If the mas is a mask, white areas are transparent and black areas opaque.
                // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101
                
                //------------------------------------------------------------------------
                // Calculate the rect we want to copy from the current context (we will use this rect for CGContext.makeImage().cropping8to: rect)
                // The principal method is we copy the context from the previous touch pos, then copy that over to the current touch pos(later down as we draw it on the context)
                //------------------------------------------------------------------------
                let radiusX: CGFloat = brushSize.width/2.0
                let radiusY: CGFloat = brushSize.height/2.0
                let previousPos: CGPoint = CGPoint(x: touchSample.previousPos.x * UIScreen.main.scale - radiusX,
                                                   y: touchSample.previousPos.y * UIScreen.main.scale - radiusY)
                let copyFromContextRect: CGRect = CGRect(origin: previousPos, size: brushSize)
                
                //------------------------------------------------------------------------
                // Copy an image from the current context, we get a CGImage. Crop it to desired size and location
                //------------------------------------------------------------------------
                
                //let cgCopy = UIGraphicsGetImageFromCurrentImageContext()?.cgImage?.cropping(to: rect) // This fails
                let cgCopy: CGImage? = ctx.makeImage()?.cropping(to: copyFromContextRect) // This works, copies the pixels of the current context, however, at this point, there is nothing in the context(it has been cleared!!!) how do we preserve the context???
                
                //------------------------------------------------------------------------
                // Apply a mask to the copied image
                //------------------------------------------------------------------------
                if let cgCopy: CGImage = cgCopy,
                   let mask: CGImage = UIImage(named: ImageNames.mask_1_S_v6)?.cgImage,
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
                    let alphaConstantFactor: CGFloat = 1.0
                    ctx.setAlpha(touchSample.force * alphaConstantFactor)
                    ctx.setBlendMode(.normal)
                    //------------------------------------------------------------------------
                    // Draw into the context
                    //------------------------------------------------------------------------
                    // Set size of the copied image we want to draw into the contex
                    let rect: CGRect = CGRect(origin: .zero, size: brushSize)
                    // Draw
                    ctx.draw(masked, in: rect)
                    
                    
                    let _rect = CGRect(x: touchSample.pos.x - brushSize.width/2.0,
                                       y: touchSample.pos.y - brushSize.height/2.0,
                                       width: brushSize.width,
                                       height: brushSize.height)
                    unionRect = unionRect.union(_rect)
                    
                    /*
                    ctx.setStrokeColor(UIColor.lightGray.cgColor)
                    ctx.setLineWidth(2)
                    ctx.addEllipse(in: rect)
                    ctx.drawPath(using: .stroke)
                    */
                    
                    //------------------------------------------------------------------------
                    // Restore the context
                    //------------------------------------------------------------------------
                    ctx.restoreGState()
                }
            }
            
            self.setNeedsDisplay(unionRect)
        }
    }
    
    /// Takes the result of the smudgebrush (a copy of the canvas ROI), blends it with the brush color and returns a resulting CGImage that is a blend between the smudge and the intrinsic color of the brush.
    func createWetBrush(_ smudgeBrush: CGImage, force: CGFloat = 1.0) -> CGImage? {
        
        // TODO: preserve the dirty color into the brush, letting the intrinsic color change, rather start out clean (this should be user uption as well)

        guard
            let brush: CGImage = brushImage?.cgImage,
            let size: CGSize = brushImage?.size else { return nil }
        
        /* Default
        if let ctx: CGContext = CGContext(data: nil,
                                          width: smudgeBrush.width,
                                          height: smudgeBrush.height,
                                          bitsPerComponent: smudgeBrush.bitsPerComponent,
                                          bytesPerRow: smudgeBrush.bytesPerRow,
                                          space: smudgeBrush.colorSpace!,
                                          bitmapInfo: smudgeBrush.bitmapInfo.rawValue)
         */
        
        //debug
        //print("smudgeBrush.colorSpace: \(smudgeBrush.colorSpace)") // Optional(<CGColorSpace 0x2812d4660> (kCGColorSpaceICCBased; kCGColorSpaceModelRGB; sRGB IEC61966-2.1))
        //print("smudgeBrush.bitmapInfo: \(smudgeBrush.bitmapInfo)") // CGBitmapInfo(rawValue: 1)
        //print("smudgeBrush.bitsPerComponent: \(smudgeBrush.bitsPerComponent)") // 8
        //print("smudgeBrush.bitsPerPixel: \(smudgeBrush.bitsPerPixel)") // 32
        //print("size: \(size)") // (81.0, 81.0)
        //print("smudgeBrush.bytesPerRow: \(smudgeBrush.bytesPerRow)") // 4096, a multiple of 32
        /*
         On bytesPerRow:
         
         Note, tye byters per row(Stride) can be larger than the width of the image. The extra bytes at the end of each row
         are simply ignored. The butes for the pixel at (x,y) start at offset y * bpr + x * bpp (where bpr is bytes-per-row and bpp is bytes-per-pixel).
         
         The CPUs in modern Macs have instructions that operate on 16 or 32 or 64 bytes at a time, so the CGImage algorithms can be more efficient if the image's stride is a multiple of 16 or 32 or 64.
         CGDisplayCreateImage was weritten by someone who knows this.
         https://stackoverflow.com/questions/25706397/cgimageref-width-doesnt-agree-with-bytes-per-row
         */
        
        
        // Example on how to create a cgColor space manually (not from the cgimage)
        // See https://developer.apple.com/forums/thread/679891
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/csintro/csintro_colorspace/csintro_colorspace.html#//apple_ref/doc/uid/TP30001148-CH222-BBCBDGDD
        // Quartz 2D programming guide
        // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007533-SW1
        
        // So it seems the below, is the same as the smudgeBrush colorspace and bitmapInfo data
        let colorSpace: CGColorSpace? = CGColorSpace(name: CGColorSpace.sRGB)
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue
        //debug
        //print("bitmapInfo: \(bitmapInfo)") // 1
        //print("colorSpace: \(colorSpace)") // Optional(<CGColorSpace 0x282d5c420> (kCGColorSpaceICCBased; kCGColorSpaceModelRGB; sRGB IEC61966-2.1))
        
        if let ctx: CGContext = CGContext(data: nil,
                                          width: smudgeBrush.width,
                                          height: smudgeBrush.height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: 4096, // We could pass in 0 here and let the method calculate it based on the bitPerCompoment and width arg. However if we pass in, 81*32 is less efficient thant 4096
                                          space: colorSpace!,
                                          bitmapInfo: bitmapInfo)
        {
            
            // Save state
            ctx.saveGState()
           
            // Construct the rect
            let rect: CGRect = CGRect(origin: .zero, size: size)
            
            //------------------------------------------------------------------
            // Draw the smudge color into the context
            //------------------------------------------------------------------
            ctx.draw(smudgeBrush, in: rect)
            
            //------------------------------------------------------------------
            // Draw the brush intrinsic color over the smudge color (with an appropriate alpha)
            // Next we draw that user selected intrinsic brush color into the context
            // TODO: Should vary depending various factors, but deal with that later. The alphi is a bidirectional control and this determines how much the color from the canvas blends with the intrinsic color of the brush. This should vary depending on several factors, e.g. wetness of the paint in the brush, wetness of paint lying on the canvas, user pressure and so on.
            //------------------------------------------------------------------
            ctx.setAlpha(0.2 * force)
            ctx.draw(brush, in: rect)
            
            // Restore state
            ctx.restoreGState()
            
            if let cg: CGImage = ctx.makeImage() {
                
                if self.brushColorCanGetDirty {
                    let im: UIImage = UIImage(cgImage: cg)
                    self.brushImage = im
                }
         
                return cg
            }
        }
        
        return nil
    }
    func wetBrush() {

        guard self.touchSamples.count > 0 else { return }
        
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: bounds.size)

        self.canvas = renderer.image { context in
            
            // Draw current state of the image into the context, because UIKit/CoreGraphics clears the context before drawing.
            // So we need to draw the latest canvas into the context to draw over.
            self.canvas?.draw(in: bounds)
            
            let ctx: CGContext = context.cgContext
            
            // Inside the point loop, we will continuously add rects, for a final rect encompassing all points, for the setneedsdisplay(rect) call at the end
            
            guard let first: Sample = touchSamples.first else { return }
            // Start of the unionRect at the first touch position rect (then later this unionrect will be expanded as needed starting from this starting rect).
            var unionRect: CGRect = CGRect(x: first.previousPos.x * UIScreen.main.scale,
                                           y: first.previousPos.y * UIScreen.main.scale,
                                           width: brushSize.width,
                                           height: brushSize.height)
            
//            for touchSample in self.touchSamples {
            for i in 1 ..< self.touchSamples.count {
                
                let touchSample: Sample = self.touchSamples[i]
                
                let brushSize: CGSize = CGSize(width: brushSize.width, height: brushSize.height)

                // If the mask is an image, then white areas are opaque, and black areas are transparent
                // If the mas is a mask, white areas are transparent and black areas opaque.
                // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101
                
                //------------------------------------------------------------------------
                // Calculate the rect we want to copy from the current context (we will use this rect for CGContext.makeImage().cropping8to: rect)
                // The principal method is we copy the context from the previous touch pos, then copy that over to the current touch pos(later down as we draw it on the context)
                //------------------------------------------------------------------------
                let radiusX: CGFloat = brushSize.width/2.0
                let radiusY: CGFloat = brushSize.height/2.0
                let previousPos: CGPoint = CGPoint(x: touchSample.previousPos.x * UIScreen.main.scale - radiusX,
                                                   y: touchSample.previousPos.y * UIScreen.main.scale - radiusY)
                let copyFromContextRect: CGRect = CGRect(origin: previousPos, size: brushSize)
                
                //------------------------------------------------------------------------
                // Copy an image from the current context, we get a CGImage. Crop it to desired size and location
                //------------------------------------------------------------------------
                
                //let cgCopy = UIGraphicsGetImageFromCurrentImageContext()?.cgImage?.cropping(to: rect) // This fails
                let cgCopy: CGImage? = ctx.makeImage()?.cropping(to: copyFromContextRect) // This works, copies the pixels of the current context, however, at this point, there is nothing in the context(it has been cleared!!!) how do we preserve the context???
                
                //------------------------------------------------------------------------
                // Apply a mask to the copied image
                //------------------------------------------------------------------------
                if let cgCopy: CGImage = cgCopy,
                   let mask: CGImage = UIImage(named: ImageNames.brush1_inv)?.cgImage,
                   let masked: CGImage = cgCopy.masking(mask),
                   let wetBrush = self.createWetBrush(masked, force: touchSample.force) {
                        
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
                    let alphaConstantFactor: CGFloat = 1.0
                    ctx.setAlpha(touchSample.force * alphaConstantFactor)
                    ctx.setBlendMode(.normal)
                    //------------------------------------------------------------------------
                    // Draw into the context
                    //------------------------------------------------------------------------
                    // Set size of the copied image we want to draw into the contex
                    let rect: CGRect = CGRect(origin: .zero, size: brushSize)
                    
                    
                    
                    
                    // Draw
                    ctx.draw(wetBrush, in: rect)
                    
                    
                    let _rect = CGRect(x: touchSample.pos.x - brushSize.width/2.0,
                                       y: touchSample.pos.y - brushSize.height/2.0,
                                       width: brushSize.width,
                                       height: brushSize.height)
                    unionRect = unionRect.union(_rect)
                    
                    /*
                    ctx.setStrokeColor(UIColor.lightGray.cgColor)
                    ctx.setLineWidth(2)
                    ctx.addEllipse(in: rect)
                    ctx.drawPath(using: .stroke)
                    */
                    
                    //------------------------------------------------------------------------
                    // Restore the context
                    //------------------------------------------------------------------------
                    ctx.restoreGState()
                }
            }
            
            self.setNeedsDisplay(unionRect)
        }
    }
    
    /// We can do this as well
    /// - Parameters:
    ///     - pos: Position of the UIImageView
    func drawMask(at pos: CGPoint) {
        
        if let cg: CGImage = self.canvas?.cgImage,
           let size: CGSize = self.canvas?.size {
            
            let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: size)
            
            let img: UIImage = renderer.image { ctx in
                
                if let mask: CGImage = UIImage(named: ImageNames.mask_1_S)?.cgImage {
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
            
            self.canvas = img
            
            let view: UIImageView = UIImageView(image: self.canvas)
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
        
        if let cg: CGImage = self.canvas?.cgImage,
           let size: CGSize = self.canvas?.size {
            
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
            
            self.canvas = img
            
            let view: UIImageView = UIImageView(image: self.canvas)
            view.tag = 0xDEADBEEF
            view.center = pos
            
            //self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(view)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch: UITouch = touches.first else { return }
        
        addSample(touch)
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
        self.addSubview(self.outlineView)
        
        self.outlineView.bounds = CGRect(x: 0,
                                         y: 0,
                                         width:/* min(touchSamples.last!.force, 1.2) * */self.brushSize.width,
                                         height:/* min(touchSamples.last!.force, 1.2) * */self.brushSize.height).insetBy(dx: 5, dy: 5)
        self.outlineView.center = pos
        
        // Call the tool
        toolAction()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch: UITouch = touches.first else { return }
        
        if touch.type == .direct && self.toolSegmentIndex == 1 {
            self.brushSize = CGSize(width: 80, height: 80)
        }
        
        addSample(touch)
        let pos = touch.location(in: self)
        if let foundView = self.viewWithTag(0xDEADBEEF) {
            foundView.center = pos
        }
        self.outlineView.bounds = CGRect(x: 0,
                                         y: 0,
                                         width:/* min(touchSamples.last!.force, 1.2) * */self.brushSize.width,
                                         height:/* min(touchSamples.last!.force, 1.2) * */self.brushSize.height).insetBy(dx: 5, dy: 5)
        self.outlineView.center = pos
        
        // A simple lerp between a pair of touch positions (we want to fill the empty space with positions as to narrow the spoacing between them)
        if self.doInterpolate || self.toolSegmentIndex == 0 {
            
            let spacing: CGFloat = (self.toolSegmentIndex == 0) ? 1 : self.smudgeSpacing
            
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
                    spacingCount = max(Int(ceil(CGPoint.length(p0 - p1) / spacing)), 1)

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
        
        // Call the tool
        toolAction()

        // We are only drawing one segment a time, so empty the touch samples array, but keep the last point, because next segment will start from that.
        if let last = touchSamples.last {
            touchSamples = [last]
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.outlineView.transform = CGAffineTransform.identity
        self.touchSamples.removeAll()
        self.outlineView.removeFromSuperview()

    }
    
    private func toolAction() -> Void {
        
        // Call the tool
        switch self.toolSegmentIndex
        {
        case 0:
            self.paint()
            
        case 1:
            self.smudge()
            
        case 2:
            self.wetBrush()
            
        default:
            break
        }
    }
    
    func addSample(_ touch: UITouch) -> Void {
        
        var sample: Sample = Sample()
        
        sample.previousPos = touch.previousLocation(in: self)
        sample.pos = touch.location(in: self)
        
        if touch.force > 0 {
            sample.force = touch.force
        } else {
            sample.force = 1.0
        }
        
        self.touchSamples.append(sample)
    }
}

/*
extension CanvasView {
    
    func drawCheckerBoard() {
        
        let renderer: UIGraphicsImageRenderer = UIGraphicsImageRenderer(size: self.bounds.size)
        
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
*/
