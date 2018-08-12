//
//  ViewController.swift
//  pixelino
//
//  Created by Sandra Grujovic on 14.05.18.
//  Copyright © 2018 Sandra Grujovic. All rights reserved.
//

import UIKit
import SpriteKit
import CoreGraphics

// FIXME: Move constants to appropriate file
let DARK_GREY = UIColor(red:0.10, green:0.10, blue:0.10, alpha:1.0)
let LIGHT_GREY = UIColor(red:0.19, green:0.19, blue:0.19, alpha:1.0)
let PIXEL_SIZE = 300

// FIXME: Make this dynamic
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
let SCREEN_WIDTH = UIScreen.main.bounds.size.width
// Maximum amount of pixels shown on screen when zooming in.
let MAX_AMOUNT_PIXEL_PER_SCREEN: CGFloat = 4.0
let MAX_ZOOM_OUT: CGFloat = 0.75
// Tolerance for checking equality of UIColors.
let COLOR_EQUALITY_TOLERANCE: CGFloat = 0.1

let animationDuration: TimeInterval = 0.4
let CANVAS_WIDTH = 20
let CANVAS_HEIGHT = 20



class ViewController: UIViewController {
    
    var commandStack = [Command]()
    var canvasView: CanvasView? = nil
    var toolbarView: UIView? = nil
    var observer: AnyObject?
    var currentDrawingColor: UIColor = .black
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

    func orientationChanged (_ notification: Notification) {
        let orientation = UIDevice.current.orientation
        var rotationAngle : CGFloat = 0
        
        switch orientation {
        case .landscapeLeft:
            rotationAngle = -CGFloat.pi / 2
            
        case .landscapeRight:
            rotationAngle = CGFloat.pi / 2
            
        case .portrait:
            break
            
        case .portraitUpsideDown:
            return
            
        default:
            break
        }
        
        let rotation = SKAction.rotate(toAngle: rotationAngle, duration: animationDuration, shortestUnitArc: true)
        canvasView?.canvas.run(rotation)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOrientationObserver()
        self.canvasView = CanvasView()
        self.view.addSubview(canvasView!)
    
        registerGestureRecognizer()
        registerToolbar()
        
        setUpTabBarItems()
        
        //setUpColorPickerButton()
        //setUpExportButton()
    }
    
    fileprivate func setUpTabBarIcon(frame: CGRect, imageEdgeInsets: UIEdgeInsets, imageName: String, action: Selector) {
        let tabBarIcon = UIButton()
        tabBarIcon.frame = frame
        tabBarIcon.imageEdgeInsets = imageEdgeInsets
        tabBarIcon.setImage(UIImage(named: imageName), for: .normal)
        tabBarIcon.addTarget(self, action: action, for: .touchUpInside)
        self.view.addSubview(tabBarIcon)
    }
    
    fileprivate func setUpTabBarItems() {
        let standardImageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        // Export button.
        setUpTabBarIcon(frame: CGRect(x: SCREEN_WIDTH-70, y: SCREEN_HEIGHT-80, width: 50, height: 50), imageEdgeInsets: standardImageEdgeInsets, imageName: "Export", action: #selector(exportButtonPressed(sender:)))
        
        // Color Picker button.
        setUpTabBarIcon(frame: CGRect(x: SCREEN_WIDTH-170, y: SCREEN_HEIGHT-80, width: 50, height: 50), imageEdgeInsets: standardImageEdgeInsets, imageName: "ColorPicker", action: #selector(colorPickerButtonPressed(sender:)))
        
        // Undo button.
        setUpTabBarIcon(frame: CGRect(x: SCREEN_WIDTH-370, y: SCREEN_HEIGHT-80, width: 50, height: 50), imageEdgeInsets: standardImageEdgeInsets, imageName: "Undo", action: #selector(undoButtonPressed(sender:)))
    }
    
    @objc func colorPickerButtonPressed(sender: UIButton!) {
        let colorPickerVC = ColorPickerViewController()
        colorPickerVC.colorChoiceDelegate = self
        colorPickerVC.transitioningDelegate = self
        colorPickerVC.modalPresentationStyle = .custom
        self.present(colorPickerVC, animated: true, completion: nil)
    }
    
    @objc func exportButtonPressed(sender: UIButton!) {
        // Fetch all needed parameters from the current canvas.
        guard let canvasColorArray = self.canvasView?.canvas.getPixelColorArray(),
            let canvasWidth = self.canvasView?.canvas.getAmountOfPixelsForWidth(),
            let canvasHeight = self.canvasView?.canvas.getAmountOfPixelsForHeight() else {
                return
        }
        
        let pictureExporter = PictureExporter(colorArray: canvasColorArray, canvasWidth: canvasWidth, canvasHeight: canvasHeight, self)
        // FIXME: Currently hardcoded pixel size of exported image.
        pictureExporter.exportImage(exportedWidth: 300, exportedHeight: 300)
    }
    
    @objc func redoButtonPressed(sender: UIButton!) {
        
    }
    
    @objc func undoButtonPressed(sender: UIButton!) {
        guard let command = commandStack.popLast() else {
            return
        }
        
        command.undo()
    }

    private func setupOrientationObserver() {
        observer = NotificationCenter.default.addObserver(forName: .UIDeviceOrientationDidChange, object: nil, queue: nil, using: orientationChanged)
    }
    
    private func registerToolbar() {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        toolbarView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: screenHeight-100), size: CGSize(width: screenWidth, height: 100 )))
        toolbarView?.backgroundColor = LIGHT_GREY
        
        self.view.addSubview(toolbarView!)
    }
    
    private func registerGestureRecognizer() {
        
        // Set up gesture recognizer
        let zoomGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchFrom(_:)))
        zoomGestureRecognizer.delegate = self
        
        let navigatorGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanFrom(_:)))
        navigatorGestureRecognizer.minimumNumberOfTouches = 2
        navigatorGestureRecognizer.delegate = self
        
        let drawGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDrawFrom(_:)))
        drawGestureRecognizer.maximumNumberOfTouches = 1
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapFrom(_:)))
        
        // Add to view
        view.addGestureRecognizer(zoomGestureRecognizer)
        view.addGestureRecognizer(navigatorGestureRecognizer)
        view.addGestureRecognizer(drawGestureRecognizer)
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handlePinchFrom(_ sender: UIPinchGestureRecognizer) {

        let pinch = SKAction.scale(by: sender.scale, duration: 0.0)
        
        // Save scale attribute for later inspection, reset the original gesture scale.
        let scale = sender.scale
        sender.scale = 1.0
        
        
        let canvasXScale = canvasView?.canvas.xScale
    
        let canvasWidth = CGFloat((canvasView?.canvas.getCanvasWidth())!)
        let augmentedCanvasWidth = canvasWidth * canvasXScale!
        let pixelWidth = CGFloat((canvasView?.canvas.getPixelWidth())!)
        let augmentedPixelWidth = pixelWidth * canvasXScale!
        
      
        // Zooming out based on relative size of canvas width.
        // FIXME: If needed, change this to a relative number for different canvas sizes.
        if (augmentedCanvasWidth/SCREEN_WIDTH) < MAX_ZOOM_OUT && scale < 1 {
            return
        }
        
        // Zooming in based on pixels visible on screen independent of actual canvas size.
        if (augmentedPixelWidth > SCREEN_WIDTH/MAX_AMOUNT_PIXEL_PER_SCREEN) && scale > 1 {
            return
        }
        
        canvasView?.canvas.run(pinch)
    }
    
    @objc func handleDrawFrom(_ sender: UIPanGestureRecognizer) {
        let canvasScene = canvasView?.canvasScene
        
        let touchLocation = sender.location(in: sender.view)
        let touchLocationInScene = canvasView?.convert(touchLocation, to: canvasScene!)
        
        let nodes = canvasScene?.nodes(at: touchLocationInScene!)
        
        nodes?.forEach({ (node) in
            if let pixel = node as? Pixel {
                pixel.fillColor = currentDrawingColor
            }
        })
    }
    
    @objc func handleTapFrom(_ sender: UITapGestureRecognizer) {
        let canvasScene = canvasView?.canvasScene
        
        let touchLocation = sender.location(in: sender.view)
        let touchLocationInScene = canvasView?.convert(touchLocation, to: canvasScene!)
        
        let nodes = canvasScene?.nodes(at: touchLocationInScene!)
        
        nodes?.forEach({ (node) in
            if let pixel = node as? Pixel {
                // pixel.fillColor = isEqual(firstColor: pixel.fillColor, secondColor: currentDrawingColor) ? UIColor.white : currentDrawingColor
                var drawCommand = DrawCommand(oldColor: pixel.fillColor, newColor: currentDrawingColor, pixel: pixel)
                commandStack.append(drawCommand)
                drawCommand.execute()
            }
        })
    }
    
    // Custom method to check for equality for UIColors.
    // FIXME: chosen tolerance value more sophisticatedly.
    private func isEqual(firstColor: UIColor, secondColor: UIColor) -> Bool {
        if firstColor == secondColor {
            return true
        } else if firstColor.isEqualToColor(color: secondColor, withTolerance: COLOR_EQUALITY_TOLERANCE) {
            return true
        }
        return false
    }
    
    @objc func handlePanFrom(_ sender: UIPanGestureRecognizer) {
        let canvasScene = canvasView?.canvasScene
        
        let translation = sender.translation(in: canvasView)

        let xScale = canvasScene?.xScale
        let yScale = canvasScene?.yScale

        let pan = SKAction.moveBy(x: translation.x * xScale! , y:  -1.0 * translation.y * yScale!, duration: 0)
        
        canvasView?.canvas.run(pan)
        sender.setTranslation(CGPoint.zero, in: canvasView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// Extension for handling half-views such as for the color picker tool.
extension ViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return SplitPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// Extension for writing back colors from the color picker view.
extension ViewController: ColorChoiceDelegate {
    func colorChoicePicked(_ color: UIColor) {
        self.currentDrawingColor = color
    }
}


