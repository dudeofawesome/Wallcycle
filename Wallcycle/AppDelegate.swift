//
//  AppDelegate.swift
//  Wallcycle
//
//  Created by Louis Orleans on 3/16/15.
//  Copyright (c) 2015 Louis Orleans. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var imageFolder: NSTextField!
    @IBOutlet weak var selectImageFolder: NSButton!
    @IBOutlet weak var interval: NSTextField!
    @IBOutlet weak var randomize: NSButton!
    @IBOutlet weak var save: NSButton!
    @IBOutlet weak var cancel: NSButton!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func onBtnSelectImageFolder(sender: NSButton) {
        let openPanel:NSOpenPanel = NSOpenPanel()
        openPanel.nameFieldLabel = "Select wallpaper folder"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        
        if (openPanel.runModal() == NSOKButton) {
            imageFolder.stringValue = (openPanel.URL?.absoluteString)!
        }
    }
    
    @IBAction func onBtnSave(sender: NSButton) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(imageFolder.stringValue, forKey: "FolderPath")
        defaults.setBool(randomize.state == NSOnState, forKey: "Randomize")
        defaults.setInteger(interval.integerValue, forKey: "SwitchTime")
        defaults.synchronize()
        
        setWallpaper()
        window.close()
    }

    @IBAction func onBtnCancel(sender: NSButton) {
        window.close()
    }
    
    func setWallpaper () {
        
    }
}

