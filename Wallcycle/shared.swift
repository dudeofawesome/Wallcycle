//
//  shared.swift
//  Wallcycle
//
//  Created by Louis Orleans on 3/17/15.
//  Copyright (c) 2015 Louis Orleans. All rights reserved.
//

import Foundation
import Cocoa
import Appkit

struct Vector2 {
    var x:Int
    var y:Int
}

struct Wallpaper {
    enum Special {case STANDARD; case CHROMA;}
    
    var path:String
    var size:Vector2
    var multiMonitor:Bool
    var special:Special
}

struct Monitor {
    var screen:NSScreen
    var position:Vector2
    var size:Vector2
}

struct ImageProcessor {
    func cropToFit (monitors:[Monitor], totalRealestate:Vector2, image:NSImage, wallpaper:Wallpaper) -> [NSImage] {
        var images:[NSImage] = []
        let wallpaperRatio:Double = Double(wallpaper.size.x) / Double(wallpaper.size.y)
        let monitorRatio:Double = Double(totalRealestate.x) / Double(totalRealestate.y)
        if (wallpaperRatio <= monitorRatio) {
            let splitWidth:Int = wallpaper.size.x / monitors.count
            for i in 0..<monitors.count {
                let rect = NSRect(x: splitWidth * i, y: 0, width: splitWidth, height: Int(wallpaper.size.y))
                println(rect)
                images.append(imageResize(image, size: rect))
            }
        } else if (wallpaperRatio > monitorRatio) {
            let splitWidth:Int = (totalRealestate.x / monitors.count) * (wallpaper.size.y / totalRealestate.y)
            let padding:Int = (wallpaper.size.x % totalRealestate.x) / 2
            for i in 0..<monitors.count {
                let rect = NSRect(x: splitWidth * i + padding, y: 0, width: splitWidth, height: Int(image.size.height))
                println(rect)
                images.append(imageResize(image, size: rect))
            }
        }
        return images
    }
    
    func chromaShift (images:[NSImage]) -> [NSImage] {
        var newImages:[NSImage] = []
        for i:Int in 0..<images.count {
            // TODO: shift through whole color wheel
            newImages.append(shiftHue(images[i], hue: 180))
        }
        
        return newImages
    }
    
    func imageResize (source:NSImage, size:NSRect) -> NSImage {
        var smallImage:NSImage = NSImage.init(size:NSSize(width:size.size.width, height:size.size.height))
        smallImage.lockFocus()
        //currentContext.setImageInterpolation(NSImageInterpolationHigh)
        source.drawAtPoint(NSPoint(x:0, y:0), fromRect:CGRectMake(size.origin.x, size.origin.y, size.size.width, size.size.height), operation:NSCompositingOperation.CompositeCopy, fraction:1.0)
        smallImage.unlockFocus()
        return smallImage
    }
    
    func writeToDisk (fm:NSFileManager, images:[NSImage]) -> [NSURL] {
        var paths:[NSURL] = []
        for i:Int in 0..<images.count {
            let date = NSDate()
            let comps = NSCalendar.currentCalendar().components(.CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
            let timestamp:String = String(comps.minute) + String(comps.second)
            let name:String = ("screen" + timestamp + String(i) + ".png")
            var newPath:NSURL = NSURL(fileURLWithPath: Utils().createTempDirectory(fm)! + "/" + name)!
            images[i].TIFFRepresentation?.writeToURL(newPath, atomically: false)
            println(newPath)
            paths.append(newPath)
        }
        
        return paths
    }
    
    func shiftHue (img:NSImage, hue:Float) -> NSImage {
        var inputImage:CIImage = CIImage(data: img.TIFFRepresentation)
        
        var hueAdjust:CIFilter = CIFilter(name:"CIHueAdjust")
        hueAdjust.setValue(inputImage, forKey: "inputImage")
        hueAdjust.setValue(hue, forKey: "inputAngle")
        var outputImage:CIImage = hueAdjust.outputImage
        
        var resultImage:NSImage = NSImage(size: outputImage.extent().size)
        var rep:NSCIImageRep = NSCIImageRep(CIImage: outputImage)
        resultImage.addRepresentation(rep);
        
        return resultImage;
    }
}

struct Utils {
    func setLaunchD () {
        
    }
    
    func createTempDirectory(fm:NSFileManager) -> String? {
        let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("wallcycle/split-walls")
        var err: NSErrorPointer = nil
        
        if fm.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: err) {
            return tempDirectoryTemplate
        } else {
            return nil
        }
    }
}