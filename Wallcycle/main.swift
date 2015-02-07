//
//  main.swift
//  Wallcycle
//
//  Created by Louis Orleans on 2/2/15.
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

public class Wallcycle {
    var workspace:NSWorkspace
    let SWITCHTIME:Double = 1 //15 * 60
    let FOLDERPATH:String = "/Volumes/Files/Pictures/Wallpapers/"
    var fm:NSFileManager
    let imgProc:ImageProcessor = ImageProcessor()
    
    var currentWallpaper:Int = 0
    var randomize:Bool = true
    var wallpapers:[Wallpaper] = []
    var monitors:[Monitor] = []
    var totalRealestate:Vector2 = Vector2(x:0, y:0)
    
    public func update() {
        println("update fired")
        if (randomize) {
            currentWallpaper = Int(arc4random_uniform(UInt32(wallpapers.count)))
            setWallpaper()
        } else {
            currentWallpaper++
            if (currentWallpaper >= wallpapers.count) {
                currentWallpaper = 0
            }
            setWallpaper()
        }
    }
    
    func setWallpaper () {
        fm.removeItemAtPath(NSTemporaryDirectory().stringByAppendingPathComponent("wallcycle/split-walls"), error: nil)
        let wallpaper = wallpapers[currentWallpaper]
        var error:NSError?
        var paths:[NSURL] = [NSURL.fileURLWithPath(wallpaper.path)!]
        
        if (wallpaper.multiMonitor && monitors.count > 1) {
            paths = imgProc.cropToFit(fm, monitors: monitors, totalRealestate: totalRealestate, wallpaper: wallpaper)
        }
        if (wallpaper.special == Wallpaper.Special.CHROMA) {
            paths = imgProc.chromaShift(fm, paths: paths)
        }
        
        for i:Int in 0..<monitors.count {
            workspace.setDesktopImageURL(paths[((i < paths.count) ? i : paths.count - 1)], forScreen: monitors[i].screen, options: nil, error: &error)
        }
    }

    init() {
        if let screens = NSScreen.screens() {
            for screen in screens {
                monitors.append(Monitor(screen: screen as NSScreen, position: Vector2(x: 0, y: 0), size: Vector2(x: Int(screen.frame.width), y: Int(screen.frame.height))))
                // TODO: this won't work if the screens aren't all aligned perfectly in settings (ie: they have any offset)
                totalRealestate.x += Int(screen.frame.width)
                totalRealestate.y = (Int(screen.frame.height) > totalRealestate.y) ? Int(screen.frame.height) : totalRealestate.y
            }
        }
        
        workspace = NSWorkspace.sharedWorkspace()
        
        fm = NSFileManager.defaultManager()
        let enumerator:NSDirectoryEnumerator = fm.enumeratorAtPath(FOLDERPATH)!
        
        while let element = enumerator.nextObject() as? String {
            var multiMonitor:Bool = false
            var special:Wallpaper.Special = Wallpaper.Special.STANDARD
            // TODO: change multimonitor detection to actually compare the wallpaper w/ the monitors, that way we won't try to apply a multimonitor wallpaper
            //          innapropriately on an ultra-widescreen monitor
            if (element.lowercaseString.rangeOfString("mm-") != nil) {
                multiMonitor = true
            }
            if (element.lowercaseString.rangeOfString("cs-") != nil) {
                special = Wallpaper.Special.CHROMA
            }
            
            let path:String = FOLDERPATH + element;
            var img:NSImageRep = NSImageRep.imageRepsWithContentsOfFile(path)?[0] as NSImageRep
            
            wallpapers.append(Wallpaper(path: path, size: Vector2(x: img.pixelsWide, y: img.pixelsHigh), multiMonitor: multiMonitor, special: special))
        }
        
//        NSTimer.scheduledTimerWithTimeInterval(SWITCHTIME, target: self, selector: "update:", userInfo: nil, repeats: true)
        // TODO: this should work, but it doesn't :/ perhaps it doens't work because the main thread ends gets killed here?
//        let myTimer = NSTimer(timeInterval: SWITCHTIME, target: self, selector: "update", userInfo: nil, repeats: true)
//        NSRunLoop.currentRunLoop().addTimer(myTimer, forMode: NSRunLoopCommonModes)
        update()
    }
}

struct ImageProcessor {
    func cropToFit (fm:NSFileManager, monitors:[Monitor], totalRealestate:Vector2, wallpaper:Wallpaper) -> [NSURL] {
        var paths:[NSURL] = []
        let wallpaperRatio:Double = Double(wallpaper.size.x) / Double(wallpaper.size.y)
        let monitorRatio:Double = Double(totalRealestate.x) / Double(totalRealestate.y)
        if (wallpaperRatio <= monitorRatio) {
            var original:NSImage = NSImage(contentsOfFile: wallpaper.path)!
            let splitWidth:Int = wallpaper.size.x / monitors.count
            for i in 0..<monitors.count {
                let rect = NSRect(x: splitWidth * i, y: 0, width: splitWidth, height: Int(wallpaper.size.y))
                println(rect)
                let img:NSImage = imageResize(original, size: rect)
                let date = NSDate()
                let comps = NSCalendar.currentCalendar().components(.CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
                let timestamp:String = String(comps.minute) + String(comps.second)
                let name:String = ("screen" + timestamp + String(i) + ".png")
                let url = NSURL.fileURLWithPath(name);
                let data:NSData = NSData()
                // TODO: make this not further compress the image (tut saved in bookmarks)
                img.TIFFRepresentation?.writeToURL(url!, atomically: false)
                let destination:NSURL = NSURL(fileURLWithPath: createTempDirectory(fm)! + "/" + name)!
                fm.moveItemAtURL(url!, toURL: destination, error: nil)
                paths.append(destination)
            }
        } else if (wallpaperRatio > monitorRatio) {
            var original:NSImage = NSImage(contentsOfFile: wallpaper.path)!
            let splitWidth:Int = (totalRealestate.x / monitors.count) * (wallpaper.size.y / totalRealestate.y)
            let padding:Int = (wallpaper.size.x % totalRealestate.x) / 2
            for i in 0..<monitors.count {
                let rect = NSRect(x: splitWidth * i + padding, y: 0, width: splitWidth, height: Int(original.size.height))
                let img:NSImage = imageResize(original, size: rect)
                println(rect)
                let date = NSDate()
                let comps = NSCalendar.currentCalendar().components(.CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
                let timestamp:String = String(comps.minute) + String(comps.second)
                let name:String = ("screen" + timestamp + String(i) + ".png")
                let url = NSURL.fileURLWithPath(name);
                let data:NSData = NSData()
                // TODO: make this not further compress the image (tut saved in bookmarks)
                img.TIFFRepresentation?.writeToURL(url!, atomically: false)
                let destination:NSURL = NSURL(fileURLWithPath: createTempDirectory(fm)! + "/" + name)!
                fm.moveItemAtURL(url!, toURL: destination, error: nil)
                println(destination)
                paths.append(destination)
            }
        }
        return paths
    }
    
    func chromaShift (fm:NSFileManager, paths:[NSURL]) -> [NSURL] {
        var newPaths:[NSURL] = []
        for i:Int in 0..<paths.count {
            var original:NSImage = NSImage(contentsOfURL: paths[i])!
            var shifted:NSImage = shiftHue(original, hue: 180)
            // TODO: make sure we aren't overwriting the original image in the wallpapers dir
            let date = NSDate()
            let comps = NSCalendar.currentCalendar().components(.CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
            let timestamp:String = String(comps.minute) + String(comps.second)
            let name:String = ("screen" + timestamp + String(i) + ".png")
            var newPath:NSURL = NSURL(fileURLWithPath: createTempDirectory(fm)! + "/" + name)!
            shifted.TIFFRepresentation?.writeToURL(newPath, atomically: false)
            newPaths.append(newPath)
        }
        
        return newPaths
    }
    
    func imageResize (source:NSImage, size:NSRect) -> NSImage {
        var smallImage:NSImage = NSImage.init(size:NSSize(width:size.size.width, height:size.size.height))
        smallImage.lockFocus()
        //currentContext.setImageInterpolation(NSImageInterpolationHigh)
        source.drawAtPoint(NSPoint(x:0, y:0), fromRect:CGRectMake(size.origin.x, size.origin.y, size.size.width, size.size.height), operation:NSCompositingOperation.CompositeCopy, fraction:1.0)
        smallImage.unlockFocus()
        return smallImage
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

func createTempDirectory(fm:NSFileManager) -> String? {
    let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("wallcycle/split-walls")
    var err: NSErrorPointer = nil
    
    if fm.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: err) {
        return tempDirectoryTemplate
    } else {
        return nil
    }
}

let wallcycle:Wallcycle = Wallcycle()