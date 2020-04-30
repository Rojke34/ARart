//
//  ViewController.swift
//  ARart
//
//  Created by Kevin on 15/04/20.
//  Copyright © 2020 Kevin. All rights reserved.
//

import UIKit
import ARKit

struct Layer {
    var node: SCNNode
    var scale: SCNVector3
}

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
    
    var birds: [UIImage] = {
        var array: [UIImage] = []
        
        for index in 1...71 {
            let im = UIImage(named: "birds_\(index)")!
            array.append(im)
        }
        
       return array
    }()
      
    var bg: [UIImage] = {
        var array: [UIImage] = []
         
         for index in 1...71 {
             let im = UIImage(named: "bg_\(index)")!
             array.append(im)
         }
         
        return array
    }()
      
    var woman: [UIImage] = {
        var array: [UIImage] = []
         
         for index in 1...71 {
             let im = UIImage(named: "girl_\(index)")!
             array.append(im)
         }
         
        return array
        
    }()

    var layers = [Layer]()
    
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
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var status = "Loading..."
        switch camera.trackingState {
        case ARCamera.TrackingState.notAvailable:
            status = "Not available"
        case ARCamera.TrackingState.limited(_):
            status = "Analyzing..."
        case ARCamera.TrackingState.normal:
            status = "Ready"
        }
        
        sessionInfoLabel.text = status
    }
        
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        #if DEBUG
            let distance = simd_distance(node.simdTransform.columns.3, (self.sceneView.session.currentFrame?.camera.transform.columns.3)!);
            
            for index in layers {
                index.node.scale = SCNVector3(x: index.scale.x + (index.scale.x * distance), y: index.scale.y + (index.scale.y * distance), z: 0.5)
            }
        #endif
    }
    
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
                self.layers.removeAll()
                
                //Create four plane around the tracked image with occlusion material
                self.filterOcclusion(on: mainNode, width: w, height: h)
                
                // Introduce virtual content
                // To introduce animation content first create an images array
                
                DispatchQueue.main.async { // Correct
                    self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.01, name: "child", order: 3005, hasAnimation: false, images: nil)
                }
                
//                self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.03, name: "001_montana.png", order: 3005, hasAnimation: false, images: nil)
//                self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.06, name: "002_bosque.png", order: 3005, hasAnimation: false, images: nil)
//                self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.09, name: "003_pueblo.png", order: 3005, hasAnimation: true, images: self.bg)
//                self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.35, name: "004_ladera.png", order: 3005, hasAnimation: true, images: self.birds)
//                self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.60, name: "000_cielo.png", order: 3005, hasAnimation: true, images: self.woman)
//                self.displayLayerView(on: mainNode,  w: w, h: h, z: 0.15, name: "005_firma.png", order: 3005, hasAnimation:  false, images: nil)
                
            })
        }
    }
    
    func filterOcclusion(on rootNode: SCNNode, width: CGFloat, height: CGFloat) {
        // MARK: - TODO Refactoring
        let occlusionNode = SCNNode()
        let colors: [UIColor] = [.red, .blue, .yellow, .green]
        let zPosition: [Float] = [0, 0.001, 0.002, 0.003]
        let postion: [Float] = [Float((height / 2) + height * 2), -Float((height / 2) + height * 2), -Float((width / 2) + width * 2), Float((width / 2) + width * 2)]
        
        for index in 1...4 {
            let plane = SCNPlane(width: width * 4, height: height * 4)
            plane.firstMaterial?.diffuse.contents = colors[index - 1]
            
            let node = SCNNode(geometry: plane)
            node.renderingOrder = -100
            
            if index < 3 {
                node.position.y = postion[index - 1]
            } else {
                node.position.x = postion[index - 1]
            }
            
            node.position.z = zPosition[index - 1]
            node.opacity = 1
            node.geometry?.firstMaterial = occlusionMaterial
            
            occlusionNode.addChildNode(node)
        }
        
        rootNode.addChildNode(occlusionNode)
    }
    
    func displayLayerView(on rootNode: SCNNode, w width: CGFloat, h height: CGFloat, z zPosition: Float, name: String, order reoderingOrder: Int, hasAnimation: Bool, images: [UIImage]?) {
        let node = SCNNode()
        
        if hasAnimation {
            if let imagesArray = images {
                let animateLayer = AnimatedPlane(width: width, height: height, desiredFPS: 15, images: imagesArray)
                animateLayer.startAnimation()
                
                node.geometry = animateLayer
            }
        } else {
            
            
            let gifImage = UIImage.gifImageWithName(name)
            let gifImageView = UIImageView(image: gifImage)
            
            let layer = SCNPlane(width: width, height: height)
            layer.firstMaterial?.diffuse.contents = gifImageView
            
            node.geometry = layer
        }
                
        node.position.z = zPosition
        //layerNode.renderingOrder = -reoderingOrder
        
        rootNode.addChildNode(node)
    }
        
    func highlightDetection(on rootNode: SCNNode, width: CGFloat, height: CGFloat, completionHandler block: @escaping (() -> Void)) {
        let planeNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        planeNode.position.z = 0.01
        planeNode.opacity = 1
        
        rootNode.addChildNode(planeNode)
        
        planeNode.runAction(self.imageHighlightAction) { block() }
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
    
}
