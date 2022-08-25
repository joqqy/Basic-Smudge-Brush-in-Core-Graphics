//
//  ViewController.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import UIKit

class ViewController: UIViewController {

    var canvas: CanvasView!

    @IBOutlet weak var toolSwitch: UISegmentedControl!
    
    @IBAction func toolAction(_ sender: UISegmentedControl) {
        
        if let canvas = canvas {
            canvas.toolSegmentIndex = sender.selectedSegmentIndex
            canvas.touchSamples.removeAll()            
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let canvasSize: CGSize = CGSize(width: 512.0, height: 512.0)
        let origin: CGPoint = CGPoint(x: self.view.center.x - canvasSize.width/2,
                                      y: self.view.center.y - canvasSize.height/2 + 50)
        let rect: CGRect = CGRect(origin: origin, size: canvasSize)
        self.canvas = CanvasView(frame: rect)
        
        if let canvas = canvas {
            self.view.addSubview(canvas)
        }
    }
}

