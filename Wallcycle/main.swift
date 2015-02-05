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
    enum Fit {case FILL; case FIT; case STRETCH; case CENTER}
    
    var path:String
    var size:Vector2
    var multiMonitor:Bool
    var fit:Fit
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
        fm.removeItemAtPath(NSTemporaryDirectory().stringByAppendingPathComponent("split-walls"), error: nil)
        let wallpaper = wallpapers[currentWallpaper]
        var imgurl:NSURL = NSURL.fileURLWithPath(wallpaper.path)!
        var error:NSError?
        
        if (wallpaper.multiMonitor) {
            // TODO make this apply non proportional mutli monitor wallpapers
            let wallpaperRatio = wallpaper.size.x / wallpaper.size.y
            let monitorRatio = totalRealestate.x / totalRealestate.y
            if (wallpaperRatio == monitorRatio) {
                var original:NSImage = NSImage(contentsOfFile: wallpaper.path)!
                var newImages:[NSURL] = []
                let splitWidth:Int = wallpaper.size.x / monitors.count
                for i in 0..<monitors.count {
                    let rect = NSRect(x: splitWidth * i, y: 0, width: splitWidth, height: Int(original.size.height))
                    let img:NSImage = imageResize(original, rect)
                    println(rect)
                    let date = NSDate()
                    let comps = NSCalendar.currentCalendar().components(.CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
                    let timestamp:String = String(comps.minute) + String(comps.second)
                    let name:String = ("screen" + timestamp + String(i) + ".png")
                    let url = NSURL.fileURLWithPath(name);
                    let data:NSData = NSData()
                    // TODO: make this not further compress the image (tut saved in bookmarks)
                    img.TIFFRepresentation?.writeToURL(url!, atomically: false)
                    let destination:NSURL = NSURL(fileURLWithPath: createTempDirectory()! + "/" + name)!
                    fm.moveItemAtURL(url!, toURL: destination, error: nil)
                    println(destination)
                    
                    workspace.setDesktopImageURL(destination, forScreen: monitors[i].screen, options: nil, error: &error)
                    newImages.append(url!)
                }
            }
        } else {
            for monitor in monitors {
                //                    var options:NSOptionsKey = NSWorkspaceDesktopImageScalingKey
                workspace.setDesktopImageURL(imgurl, forScreen: monitor.screen, options: nil, error: &error)
            }
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
            var multiMonitor:Bool
            if element.hasPrefix("mm-") {
                multiMonitor = true
            } else {
                multiMonitor = false;
            }
            
            let path:String = FOLDERPATH + element;
            var img:NSImageRep = NSImageRep.imageRepsWithContentsOfFile(path)?[0] as NSImageRep
            
            wallpapers.append(Wallpaper(path: path, size: Vector2(x: img.pixelsWide, y: img.pixelsHigh), multiMonitor: multiMonitor, fit: Wallpaper.Fit.FILL))
        }
        
//        NSTimer.scheduledTimerWithTimeInterval(SWITCHTIME, target: self, selector: "update:", userInfo: nil, repeats: true)
        // TODO this should work, but it doesn't :/ perhaps it doens't work because the main thread ends gets killed here?
//        let myTimer = NSTimer(timeInterval: SWITCHTIME, target: self, selector: "update", userInfo: nil, repeats: true)
//        NSRunLoop.currentRunLoop().addTimer(myTimer, forMode: NSRunLoopCommonModes)
        update()
    }
    
    func createTempDirectory() -> String? {
        let tempDirectoryTemplate = NSTemporaryDirectory().stringByAppendingPathComponent("split-walls")
        var err: NSErrorPointer = nil
        
        if fm.createDirectoryAtPath(tempDirectoryTemplate, withIntermediateDirectories: true, attributes: nil, error: err) {
            return tempDirectoryTemplate
        } else {
            return nil
        }
    }
}

func imageResize (source:NSImage, size:NSRect) -> NSImage {
    var sourceImage:NSImage = source

    var smallImage:NSImage = NSImage.init(size:NSSize(width:size.size.width, height:size.size.height))
    smallImage.lockFocus()
    //sourceImage.setSize(size)
    //currentContext.setImageInterpolation(NSImageInterpolationHigh)
//    sourceImage.drawAtPoint(NSPoint(x:size.origin.x, y:size.origin.y), fromRect:CGRectMake(0, 0, size.size.width, size.size.height), operation:NSCompositingOperation.CompositeCopy, fraction:1.0)
    sourceImage.drawAtPoint(NSPoint(x:0, y:0), fromRect:CGRectMake(size.origin.x, size.origin.y, size.size.width, size.size.height), operation:NSCompositingOperation.CompositeCopy, fraction:1.0)
    smallImage.unlockFocus()
    return smallImage
 }

let wallcycle:Wallcycle = Wallcycle()