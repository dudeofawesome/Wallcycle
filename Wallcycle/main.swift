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
    
    var currentWallpaper:Int = 0
    var randomize:Bool = false
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
        let wallpaper = wallpapers[currentWallpaper]
        var imgurl:NSURL = NSURL.fileURLWithPath(wallpaper.path)!
        var error:NSError?
        
        if (wallpaper.multiMonitor) {
            // TODO make this actually apply mutli monitor wallpapers
            // TODO: we're gonna want to crop images, and we'll use NSImageRep.setSize(...) for that
            let wallpaperRatio = wallpaper.size.x / wallpaper.size.y
            let monitorRatio = totalRealestate.x / totalRealestate.y
            if (wallpaperRatio == monitorRatio) {
                var original:NSImage = NSImage(contentsOfFile: wallpaper.path)!
                var newImages:[NSURL] = []
                let splitWidth:Int = wallpaper.size.x / monitors.count
                for i in 0..<monitors.count {
                    //original.setSize((i * splitWidth) + ((i + 1) * splitWidth), original.size.height)
                    let img:NSImage = imageResize(original, NSSize(width:(Int(i) * splitWidth) + ((Int(i) + 1) * splitWidth), height:Int(original.size.height)))
                    let url = NSURL.fileURLWithPath("screen" + String(i) + ".png");
                    let data:NSData = NSData()
                    img.TIFFRepresentation?.writeToURL(url!, atomically: false)
                    //NSFileManager.copyItemAtPath(url!, )
                    workspace.setDesktopImageURL(url!, forScreen: monitors[i].screen, options: nil, error: &error)
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
        
        let fileManager = NSFileManager.defaultManager()
        let enumerator:NSDirectoryEnumerator = fileManager.enumeratorAtPath(FOLDERPATH)!
        
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
}

func imageResize (source:NSImage, size:NSSize) -> NSImage {
    var sourceImage:NSImage = source

    var smallImage:NSImage = NSImage.init(size:size)
    smallImage.lockFocus()
    //sourceImage.setSize(size)
    //currentContext.setImageInterpolation(NSImageInterpolationHigh)
    sourceImage.drawAtPoint(NSPoint(x:0, y:0), fromRect:CGRectMake(0, 0, size.width, size.height), operation:NSCompositingOperation.CompositeCopy, fraction:1.0)
    smallImage.unlockFocus()
    return smallImage
 }

let wallcycle:Wallcycle = Wallcycle()