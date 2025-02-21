//
//  PictureExporter.swift
//  pixelino
//
//  Created by Sandra Grujovic on 07.08.18.
//  Copyright © 2018 Sandra Grujovic. All rights reserved.
//

import Foundation
import UIKit

// Handles the exporting of images to Photos library.
class PictureExporter: NSObject {

    private var rawPixelArray: [RawPixel]
    private var canvasWidth: Int
    private var canvasHeight: Int
    private let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    private let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

    init(colorArray: [UIColor], canvasWidth: Int, canvasHeight: Int) {
        self.rawPixelArray = [RawPixel]()
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        super.init()
        // Convert given UIColor array into RawPixel array.
        setUpRawPixelArray(colorArray: colorArray)
    }

    convenience init(drawing: Drawing) {
        self.init(colorArray: drawing.colorArray, canvasWidth: Int(drawing.width), canvasHeight: Int(drawing.height))
    }

    private func setUpRawPixelArray(colorArray: [UIColor]) {
        colorArray.forEach { (color) in
            do {
                let rawPixel = try RawPixel(inputColor: color)
                rawPixelArray.append(rawPixel)
            } catch {
                print("RawPixel conversion failed. \(error.localizedDescription)")
                return
            }
        }
    }

    /// This method generates an UIImage that can be saved to Photos.
    ///
    /// - Parameters:
    ///   - width: the width of the canvas.
    ///   - height: the height of the canvas.
    ///   - uiHandler: an ui handler for showing an ui update as the method progresses.
    public func generateUIImagefromDrawing(width: Int, height: Int, uiHandler: ((Double) -> Void)? = nil) -> UIImage? {

        // Build the bitmap input for the CGImage conversion.
        guard let dataProvider = CGDataProvider(data: NSData(bytes: &rawPixelArray, length: rawPixelArray.count * MemoryLayout<RawPixel>.size)
            ) else {
                print("DataProvider could not be built.")
                return nil }

        uiHandler?(0.25)

        // Create CGImage version.
        guard let cgImage = CGImage.init(width: canvasWidth, height: canvasHeight, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: canvasWidth * (MemoryLayout<RawPixel>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            print("CGImage could not be created.")
            return nil
        }

        uiHandler?(0.5)

        // Convert to UIImage for later use in UIImageView.
        guard let uiImage = UIImage(cgImage: cgImage).rotate(radians: -CGFloat.pi / 2.0) else {
            return nil
        }

        // Generate Image View for saving image by taking a screenshort.
        let imageView = UIImageView(image: uiImage)
        imageView.backgroundColor = .red
        imageView.layer.magnificationFilter = kCAFilterNearest
        imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        // Take actual screenshot from Image View context.
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, imageView.isOpaque, 0.0)
        // imageView.transform = imageView.transform.rotated(by: CGFloat.pi/2)
        imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
        guard let snapshotImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }

        UIGraphicsEndImageContext()

        uiHandler?(0.75)

        // Transform picture to correct rotation.
        /*guard let rotatedSnapshotImage = snapshotImage.rotate(radians: -CGFloat.pi/2) else {
            return nil
        }*/

        uiHandler?(1.0)

        return snapshotImage
    }

    func generateThumbnailFromDrawing() -> UIImage? {
        guard let image = generateUIImagefromDrawing(width: 300, height: 300) else {
            return nil
        }

        return image
    }
}
