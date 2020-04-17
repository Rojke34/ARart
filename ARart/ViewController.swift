//
//  ViewController.swift
//  ARart
//
//  Created by Kevin on 15/04/20.
//  Copyright © 2020 Kevin. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    var occlusionMaterial: SCNMaterial = {
        let occlusionMaterial = SCNMaterial()
        occlusionMaterial.isDoubleSided = true
        occlusionMaterial.colorBufferWriteMask = []
        occlusionMaterial.readsFromDepthBuffer = true
        occlusionMaterial.writesToDepthBuffer = true

        return occlusionMaterial
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // first see if there is a folder called "ARImages" Resource Group in our Assets Folder
        if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) {
            // if there is, set the images to track
            configuration.trackingImages = trackedImages
            // at any point in time, only 1 image will be tracked
            configuration.maximumNumberOfTrackedImages = 1
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let w = imageAnchor.referenceImage.physicalSize.width
        let h = imageAnchor.referenceImage.physicalSize.height
                
        updateQueue.async {
            self.sceneView.pointOfView?.position.z = -10.001
            
            // create a plan that has the same real world height and width as our detected image
            let mainPlane = SCNPlane(width: w, height: h)
            // This bit is important. It helps us create occlusion so virtual things stay hidden behind the detected image
            mainPlane.firstMaterial?.colorBufferWriteMask = .alpha

            let mainNode = SCNNode(geometry: mainPlane)
            mainNode.eulerAngles.x = -.pi / 2
            mainNode.opacity = 1
            node.addChildNode(mainNode)
            
            // Perform a quick animation to visualize the plane on which the image was detected.
            // We want to let our users know that the app is responding to the tracked image.
            self.highlightDetection(on: mainNode, width: w, height: h, completionHandler: {

                // MARK: - TODO Refactoring
                //TODO: CSNPlane with animation usging sequence of images
                //self.displayLayerViewAnimation(on: mainNode, width: w, height: h, z: 0.01)
                
                //Create four plane around the tracked image with occlusion material
                //self.filterOcclusion(on: mainNode, width: w, height: h)
                
                // Introduce virtual content
                
                let bg = SCNPlane(width: w, height: h)
                bg.firstMaterial = self.bgMaterial
                
                let bgNode = SCNNode(geometry: bg)
                bgNode.position.z = 0.01
                mainNode.addChildNode(bgNode)
                
                self.bgStartAnimation()
                

                let layer = SCNPlane(width: w, height: h)
                layer.firstMaterial = self.birdMaterial
                self.birdStartAnimation()
                let layerNode = SCNNode(geometry: layer)
                layerNode.position.z = 0.5
                mainNode.addChildNode(layerNode)
//
                let woman = SCNPlane(width: w, height: h)
                woman.firstMaterial = self.womanMaterial
                self.womanStartAnimation()
                let womanNode = SCNNode(geometry: woman)
                womanNode.position.z = 0.25
                mainNode.addChildNode(womanNode)
                
                
                
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.01, name: "000_cielo.png", order: 3005, hasAnimation: false)
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.03, name: "001_montana.png", order: 3005, hasAnimation: false)
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.06, name: "002_bosque.png", order: 3005, hasAnimation: false)
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.09, name: "003_pueblo.png", order: 3005, hasAnimation: false)
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.12, name: "004_ladera.png", order: 3005, hasAnimation: false)
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.13, name: "000_cielo.png", order: 3005, hasAnimation: true)
//                self.displayLayerView(on: mainNode,  width: w, height: h, z: -0.15, name: "005_firma.png", order: 3005, hasAnimation:  false)
                
            })
        }
    }
    
    func filterOcclusion(on rootNode: SCNNode, width: CGFloat, height: CGFloat) {
        // MARK: - TODO Refactoring
        let filterNode = SCNNode()
    
        let topPlane = SCNPlane(width: width * 4, height: height)
        topPlane.firstMaterial?.diffuse.contents = UIColor.red
        
        let bottomPlane = SCNPlane(width: width * 4, height: height)
        bottomPlane.firstMaterial?.diffuse.contents = UIColor.blue
        
        let leftPlane = SCNPlane(width: width, height: height * 4)
        leftPlane.firstMaterial?.diffuse.contents = UIColor.green
        
        let rightPlane = SCNPlane(width: width, height: height * 4)
        rightPlane.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let top = SCNNode(geometry: topPlane)
        top.renderingOrder = -4001
        top.position.y = Float(height)
        top.position.z = 0
        top.opacity = 1
        top.geometry?.firstMaterial = occlusionMaterial
        
        let bottom = SCNNode(geometry: bottomPlane)
        bottom.renderingOrder = -4001
        bottom.position.y = -Float(height)
        bottom.position.z = 0.00001
        bottom.opacity = 1
        bottom.geometry?.firstMaterial = occlusionMaterial
        
        let left = SCNNode(geometry: leftPlane)
        left.renderingOrder = -4001
        left.position.x = -Float(width)
        left.position.z = 0.00002
        left.opacity = 1
        left.geometry?.firstMaterial = occlusionMaterial
        
        let right = SCNNode(geometry: rightPlane)
        right.renderingOrder = -4001
        right.position.x = Float(width)
        right.position.z = 0.00003
        right.opacity = 1
        right.geometry?.firstMaterial = occlusionMaterial
        
        filterNode.addChildNode(top)
        filterNode.addChildNode(bottom)
        filterNode.addChildNode(left)
        filterNode.addChildNode(right)
        
        rootNode.addChildNode(filterNode)
    }
    
    func displayLayerView(on rootNode: SCNNode, width: CGFloat, height: CGFloat, z: Float, name: String, order reoderingOrder: Int, hasAnimation: Bool) {
        let layer = SCNPlane(width: width, height: height)
        
        
        layer.firstMaterial = birdMaterial
//        startAnimation()
        
        
        let layerNode = SCNNode(geometry: layer)
        layerNode.position.z = z * -1
        //layerNode.renderingOrder = -reoderingOrder
        
        rootNode.addChildNode(layerNode)
    }
    
    
//    func displayLayerView(on rootNode: SCNNode, width: CGFloat, height: CGFloat, z: Float, name: String, order reoderingOrder: Int, hasAnimation: Bool) {
//        let layer = SCNPlane(width: width, height: height)
//        
//        if hasAnimation {
//            layer.firstMaterial = birdMaterial
//            startAnimation()
//        } else {
//            layer.firstMaterial?.diffuse.contents = UIImage(named: name)
//        }
//        
//        let layerNode = SCNNode(geometry: layer)
//        layerNode.position.z = z * -1
//        //layerNode.renderingOrder = -reoderingOrder
//        
//        rootNode.addChildNode(layerNode)
//    }
    
    func highlightDetection(on rootNode: SCNNode, width: CGFloat, height: CGFloat, completionHandler block: @escaping (() -> Void)) {
        let planeNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        planeNode.position.z = 0.01
        planeNode.opacity = 1
        
        rootNode.addChildNode(planeNode)
        
        planeNode.runAction(self.imageHighlightAction) {
            block()
        }
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }
    
    //MARK: - TODO Animation lab refactoring
     var birds: [UIImage] = {
         
         let im1 = UIImage(named: "birds_0")!
         let im2 = UIImage(named: "birds_1")!
         let im3 = UIImage(named: "birds_2")!
         let im4 = UIImage(named: "birds_3")!
         let im5 = UIImage(named: "birds_4")!
         let im6 = UIImage(named: "birds_5")!
         let im7 = UIImage(named: "birds_6")!
         let im8 = UIImage(named: "birds_7")!
         let im9 = UIImage(named: "birds_8")!
         let im10 = UIImage(named: "birds_9")!
         let im11 = UIImage(named: "birds_10")!
         let im12 = UIImage(named: "birds_11")!
         let im13 = UIImage(named: "birds_12")!
         let im14 = UIImage(named: "birds_13")!
         
         return [im1, im2, im3, im4, im5, im6, im7, im8, im9, im10, im11, im12, im13, im14]
     }()
    
    var bg: [UIImage] = {
        
        let im1 = UIImage(named: "bg_0")!
        let im2 = UIImage(named: "bg_1")!
        let im3 = UIImage(named: "bg_0")!
        let im4 = UIImage(named: "bg_1")!
        let im5 = UIImage(named: "bg_0")!
        let im6 = UIImage(named: "bg_1")!
        let im7 = UIImage(named: "bg_0")!
        let im8 = UIImage(named: "bg_1")!
        let im9 = UIImage(named: "bg_0")!
        let im10 = UIImage(named: "bg_1")!
        
        return [im1, im2, im3, im4, im5, im6, im7, im8, im9, im10]
    }()
    
    var woman: [UIImage] = {
        
        let im1 = UIImage(named: "girl_0")!
        let im2 = UIImage(named: "girl_1")!
        let im3 = UIImage(named: "girl_2")!
        let im4 = UIImage(named: "girl_3")!
        let im5 = UIImage(named: "girl_4")!
        let im6 = UIImage(named: "girl_5")!
        let im7 = UIImage(named: "girl_6")!
        let im8 = UIImage(named: "girl_7")!
        let im9 = UIImage(named: "girl_8")!
        let im10 = UIImage(named: "girl_9")!
        let im11 = UIImage(named: "girl_10")!
        let im12 = UIImage(named: "girl_11")!
        let im13 = UIImage(named: "girl_12")!
        let im14 = UIImage(named: "girl_13")!
        
        return [im1, im2, im3, im4, im5, im6, im7, im8, im9, im10, im11, im12, im13, im14]
    }()
    
    
//    func displayLayerViewAnimation(on rootNode: SCNNode, width: CGFloat, height: CGFloat, z: Float) {
//        let layer = SCNPlane(width: width, height: height)
//        layer.firstMaterial = aniMaterial
//
//        let layerNode = SCNNode(geometry: layer)
//        layerNode.position.z = z
//        //layerNode.renderingOrder = -reoderingOrder
//
//        startAnimation()
//        rootNode.addChildNode(layerNode)
//    }
    
    
    var birdAnimationImageFrameIndex : Double = 0
    var birdDisplayLink : CADisplayLink?
    let birdMaterial = SCNMaterial()
    
    func birdStartAnimation() {
        birdAnimationImageFrameIndex = 0
        birdDisplayLink = CADisplayLink(target: self, selector: #selector(animationStep(_:)))
        birdDisplayLink!.preferredFramesPerSecond = 60
        birdDisplayLink!.add(to: .current, forMode: .default)
    }
    
    @objc func animationStep(_ displayLink: CADisplayLink) {
        let desiredFPS : Double = 24
        let realFPS = 1 / (displayLink.targetTimestamp - displayLink.timestamp)

        birdMaterial.diffuse.contents = birds[Int(birdAnimationImageFrameIndex)]
        
        birdAnimationImageFrameIndex += desiredFPS / realFPS
        
        if Int(birdAnimationImageFrameIndex) >= birds.count {
            birdAnimationImageFrameIndex = 0
            //displayLink.remove(from: .current, forMode: .default)
        }
    }
    
    var bgAnimationImageFrameIndex : Double = 0
    var bgDisplayLink : CADisplayLink?
    let bgMaterial = SCNMaterial()
    
    func bgStartAnimation() {
        bgAnimationImageFrameIndex = 0
        bgDisplayLink = CADisplayLink(target: self, selector: #selector(bganimationStep(_:)))
        bgDisplayLink!.preferredFramesPerSecond = 60
        bgDisplayLink!.add(to: .current, forMode: .default)
    }
    
    @objc func bganimationStep(_ displayLink: CADisplayLink) {
        let desiredFPS : Double = 24
        let realFPS = 1 / (displayLink.targetTimestamp - displayLink.timestamp)

        bgMaterial.diffuse.contents = bg[Int(bgAnimationImageFrameIndex)]
        
        bgAnimationImageFrameIndex += desiredFPS / realFPS
        
        if Int(bgAnimationImageFrameIndex) >= bg.count {
            bgAnimationImageFrameIndex = 0
            //displayLink.remove(from: .current, forMode: .default)
        }
    }
    
    var womanAnimationImageFrameIndex : Double = 0
    var womanDisplayLink : CADisplayLink?
    let womanMaterial = SCNMaterial()
    
    func womanStartAnimation() {
        bgAnimationImageFrameIndex = 0
        womanDisplayLink = CADisplayLink(target: self, selector: #selector(womananimationStep(_:)))
        womanDisplayLink!.preferredFramesPerSecond = 60
        womanDisplayLink!.add(to: .current, forMode: .default)
    }
    
    @objc func womananimationStep(_ displayLink: CADisplayLink) {
        let desiredFPS : Double = 24
        let realFPS = 1 / (displayLink.targetTimestamp - displayLink.timestamp)

        womanMaterial.diffuse.contents = woman[Int(womanAnimationImageFrameIndex)]
        
        womanAnimationImageFrameIndex += desiredFPS / realFPS
        
        if Int(womanAnimationImageFrameIndex) >= woman.count {
            womanAnimationImageFrameIndex = 0
            //displayLink.remove(from: .current, forMode: .default)
        }
    }

}
