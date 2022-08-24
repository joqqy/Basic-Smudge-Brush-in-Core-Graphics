//
//  ViewController.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import UIKit

class CanvaView: UIView {
    
    var image: UIImage?
    
    override func didMoveToSuperview() {
        
        self.image = UIImage(named: "tiger")
    }
    
    override func draw(_ rect: CGRect) {
        
        if let ctx: CGContext = UIGraphicsGetCurrentContext() {
            
            if let cg = self.image?.cgImage,
               let size = self.image?.size {
                
                // If the mask is an image, then white areas are opaque, and black areas are transparent
                // If the mas is a mask, white areas are transparent and black areas opaque.
                // https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-TPXREF101
                
                if let mask = UIImage(named: "tigermask_1_S")?.cgImage {
                    if let masked = cg.masking(mask) {
                        
                        let rect = CGRect(origin: .zero, size: size)
                        
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
    
}

class ViewController: UIViewController {

    var canvas: CanvaView!
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = .white
        
        self.canvas = CanvaView(frame: self.view.frame)
        if let view = self.canvas {
            self.view.addSubview(view)
        }
    }
}

