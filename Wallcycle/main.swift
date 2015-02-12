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
        } else {
            println("Where are your wallpapers stored? (You can just drag the folder in)")
            FOLDERPATH = input()
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
        
        setLaunchD()
        
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
            var img:NSImageRep = NSImageRep.imageRepsWithContentsOfFile(path)?[0] as NSImageRep
            
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
        
        update()
    }
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
            var newPath:NSURL = NSURL(fileURLWithPath: createTempDirectory(fm)! + "/" + name)!
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

func setLaunchD () {
    
}

func input() -> String {
    var keyboard = NSFileHandle.fileHandleWithStandardInput()
    var inputData = keyboard.availableData
    return NSString(data: inputData, encoding:NSUTF8StringEncoding)!
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