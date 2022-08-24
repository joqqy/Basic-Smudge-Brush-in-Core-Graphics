//
//  ViewController.swift
//  MaskTest
//
//  Created by Pierre Hanna on 2022-08-24.
//

import UIKit

class ViewController: UIViewController {

    var canvas: CanvaView!

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //self.view.backgroundColor = .white
        
        self.canvas = CanvaView(frame: self.view.frame)
        if let view: CanvaView = self.canvas {
            self.view.addSubview(view)
        }
    }
}

