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

public class Wallcycle {
    var workspace:NSWorkspace
    var SWITCHTIME:Double = 15 * 60
    var FOLDERPATH:String = "/Volumes/Files/Pictures/Wallpapers/"
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
            println(wallpapers[currentWallpaper].path)
            setWallpaper()
        } else {
            currentWallpaper++
            if (currentWallpaper >= wallpapers.count) {
                currentWallpaper = 0
            }
            println(wallpapers[currentWallpaper].path)
            setWallpaper()
        }
    }
    
    func setWallpaper () {
        fm.removeItemAtPath(NSTemporaryDirectory().stringByAppendingPathComponent("wallcycle/split-walls"), error: nil)
        let wallpaper = wallpapers[currentWallpaper]
        var error:NSError?
        var images:[NSImage] = [NSImage(contentsOfFile: wallpaper.path)!]
        
        if (images.count == 1 && wallpaper.multiMonitor && monitors.count > 1) {
            images = imgProc.cropToFit(monitors, totalRealestate: totalRealestate, image: images[0], wallpaper: wallpaper)
        } else if (images.count != 1) {println("Error: there was somehow more than 1 image at crop time")}
        if (wallpaper.special == Wallpaper.Special.CHROMA) {
             images = imgProc.chromaShift(images)
        }
        
        var paths:[NSURL] = imgProc.writeToDisk(fm, images: images)
        for i:Int in 0..<monitors.count {
            workspace.setDesktopImageURL(paths[((i < paths.count) ? i : paths.count - 1)], forScreen: monitors[i].screen, options: nil, error: &error)
        }
    }

    init() {
            // TODO: load prefs
            let defaults = NSUserDefaults.standardUserDefaults()
            if defaults.objectForKey("FolderPath") != nil {
                FOLDERPATH = defaults.objectForKey("FolderPath") as String
            }
            if defaults.objectForKey("Randomize") != nil {
                randomize = defaults.objectForKey("Randomize") as Bool
            }
            if defaults.objectForKey("SwitchTime") != nil {
                SWITCHTIME = defaults.objectForKey("SwitchTime") as Double
            }
            
            for i:Int in 1..<Process.arguments.count {
                if Process.arguments[i].hasPrefix("-") {
                    switch Process.arguments[i] {
                    case "-dir":
                        FOLDERPATH = Process.arguments[i + 1]
                        break
                    case "-rand":
                        switch Process.arguments[i + 1] {
                        case "true":
                            randomize = true
                            break
                        case "false":
                            randomize = false
                            break
                        default:
                            break
                        }
                        break
                    case "-time":
                        SWITCHTIME = (Process.arguments[i + 1] as NSString).doubleValue
                        break
                    default:
                        break
                    }
                }
            }
            // TODO: save prefs
            defaults.setObject(FOLDERPATH, forKey: "FolderPath")
            defaults.setObject(randomize, forKey: "Randomize")
            defaults.setObject(SWITCHTIME, forKey: "SwitchTime")
            defaults.synchronize()
            
            Utils().setLaunchD()
            
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
            
            // TODO: switch to only loading the image we are going to use this execution
            while let element = enumerator.nextObject() as? String {
                let path:String = FOLDERPATH + element;
                let imgs:[NSImageRep] = NSImageRep.imageRepsWithContentsOfFile(path)? as [NSImageRep]
                if (imgs.count > 0) {
                    var img:NSImageRep = imgs[0] as NSImageRep
                    var multiMonitor:Bool = false
                    var special:Wallpaper.Special = Wallpaper.Special.STANDARD
                    /* TODO: change multimonitor detection to actually compare the wallpaper w/ the monitors, that way we won't try to apply a multimonitor wallpaper
                    innapropriately on an ultra-widescreen monitor */
                    let wallpaperRatio:Double = Double(img.pixelsWide) / Double(img.pixelsHigh)
                    if (element.lowercaseString.rangeOfString("mm-") != nil || wallpaperRatio > 3.5) {
                        multiMonitor = true
                    }
                    if (element.lowercaseString.rangeOfString("cs-") != nil) {
                        special = Wallpaper.Special.CHROMA
                    }
                    
                    wallpapers.append(Wallpaper(path: path, size: Vector2(x: img.pixelsWide, y: img.pixelsHigh), multiMonitor: multiMonitor, special: special))
                }
            }
            
            //        let task = NSTask()
            //        task.launchPath = "/bin/echo"
            //        task.arguments = ["first-argument", "second-argument"]
            //
            //        let pipe = NSPipe()
            //        task.standardOutput = pipe
            //        task.launch()
            //        
            //        let data = pipe.fileHandleForReading.readDataToEndOfFile()
            //        let output:String = NSString(data: data, encoding: NSUTF8StringEncoding)!
            //        
            //        print(output)
            //        assert(output == "first-argument second-argument\n")
    }
    
    
}