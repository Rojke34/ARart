//
//  AnimatedPlane.swift
//  ARart
//
//  Created by Kevin on 23/04/20.
//  Copyright © 2020 Kevin. All rights reserved.
//

import Foundation
import ARKit

class AnimatedPlane: SCNPlane {
    
    var animationImageFrameIndex : Double = 0
    var displayLink : CADisplayLink?
    var images: [UIImage] = []
    var desiredFPS: Double = 0
    
    init(width: CGFloat, height: CGFloat, desiredFPS: Double, images: [UIImage]) {
        super.init()
        
        self.width = width
        self.height = height
        self.desiredFPS = desiredFPS
        self.images = images
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation() {
        animationImageFrameIndex = 0
        displayLink = CADisplayLink(target: self, selector: #selector(animationStep(_:)))
        displayLink!.preferredFramesPerSecond = 60
        displayLink!.add(to: .current, forMode: .default)
    }
    
    @objc func animationStep(_ displayLink: CADisplayLink) {
        let realFPS = 1 / (displayLink.targetTimestamp - displayLink.timestamp)

        self.firstMaterial?.diffuse.contents = images[Int(animationImageFrameIndex)]
        
        animationImageFrameIndex += desiredFPS / realFPS
        
        if Int(animationImageFrameIndex) >= images.count {
            animationImageFrameIndex = 0
        }
    }
    
}
