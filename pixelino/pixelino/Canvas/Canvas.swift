//
//  Canvas.swift
//  pixelino
//
//  Created by Sandra Grujovic on 11.08.18.
//  Copyright © 2018 Sandra Grujovic. All rights reserved.
//

import Foundation
import SpriteKit

class Canvas : SKSpriteNode {
    
    private var width: Int = 0
    private var height: Int = 0
    private var pixelArray = [Pixel]()
    
    init(width: Int, height: Int) {
        // TODO: Refactor this method ASAP
        self.width = width
        self.height = height
        super.init(texture: nil, color: .cyan, size: CGSize(width: width * PIXEL_SIZE, height: height * PIXEL_SIZE))
        setUpPixelGrid(width: width, height: height)
    }
    
    func getCanvasWidth() -> Int {
        return width * PIXEL_SIZE
    }
    
    func getCanvasHeight() -> Int {
        return height * PIXEL_SIZE
    }
    
    func getAmountOfPixelsForWidth() -> Int {
        return width
    }
    
    func getAmountOfPixelsForHeight() -> Int {
        return height
    }
    
    func getPixelWidth() -> Int {
        return PIXEL_SIZE
    }
    
    func getPixelHeight() -> Int {
        return PIXEL_SIZE
    }
    
    func getPixelColorArray() -> [UIColor] {
        return pixelArray.map({ (currentPixel) -> UIColor in
            return currentPixel.fillColor
        })
    }
    
    private func setUpPixelGrid(width: Int, height: Int) {
        for x in 0..<width {
            for y in 0..<height {
                
                // This is nasty, but SpriteKit has a stupid bug...
                let xPos = Int(-self.size.width / 2) + x * Int(PIXEL_SIZE)
                let yPos = Int(-self.size.height / 2) + y * Int(PIXEL_SIZE)
                
                let pixel = Pixel()
                
                pixel.position.x = CGFloat(xPos)
                pixel.position.y = CGFloat(yPos)
                pixelArray.append(pixel)
                
                self.addChild(pixel)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func draw(pixel: Pixel, color: UIColor) {
        pixel.fillColor = color
    }
    
    
}
