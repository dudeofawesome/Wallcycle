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

public class Wallcycle {
    var leftScreen:NSScreen
    var rightScreen:NSScreen
    var workspace:NSWorkspace
    let SWITCHTIME:Double = 1 //15 * 60
    let FOLDERPATH:String = "/Volumes/Files/Pictures/Wallpapers/"
    
    var currentWallpaper:Int = 0
    var randomize:Bool = true
    var wallpapers:[Wallpaper] = []
    
    public func update() {
        println("timer fired")
        if (randomize) {
            currentWallpaper = Int(arc4random_uniform(UInt32(wallpapers.count)))
            var imgurl:NSURL = NSURL.fileURLWithPath(wallpapers[currentWallpaper].path)!
            var error:NSError?
            
            workspace.setDesktopImageURL(imgurl, forScreen: leftScreen, options: nil, error: &error)
            workspace.setDesktopImageURL(imgurl, forScreen: rightScreen, options: nil, error: &error)
            
        } else {
            currentWallpaper++
            if (currentWallpaper >= wallpapers.count) {
                currentWallpaper = 0
            }
            var imgurl:NSURL = NSURL.fileURLWithPath(wallpapers[currentWallpaper].path)!
            var error : NSError?
            
            workspace.setDesktopImageURL(imgurl, forScreen: leftScreen, options: nil, error: &error)
            workspace.setDesktopImageURL(imgurl, forScreen: rightScreen, options: nil, error: &error)
            
        }
    }

    init() {
        leftScreen = NSScreen.screens()?[0] as NSScreen
        rightScreen = NSScreen.screens()?[1] as NSScreen
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
        // TODO this should work, but it doesn't :/
//        let myTimer = NSTimer(timeInterval: SWITCHTIME, target: self, selector: "update", userInfo: nil, repeats: true)
//        NSRunLoop.currentRunLoop().addTimer(myTimer, forMode: NSRunLoopCommonModes)
        
        let date:NSDate = NSDate()
        var lastLoopTime:Int = 0 //Int(date.timeIntervalSince1970)
        while (true) {
            if ((Int(date.timeIntervalSince1970) - lastLoopTime) * 1000 > Int(SWITCHTIME)) {
                println("looping this time")
                update()
                lastLoopTime = Int(date.timeIntervalSince1970)
            } else {
                println(Int(date.timeIntervalSince1970) - lastLoopTime)
            }
        }
    }
}

let wallcycle:Wallcycle = Wallcycle()