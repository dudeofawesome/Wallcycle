//
//  ViewController.swift
//  Wallcycle
//
//  Created by Louis Orleans on 3/17/15.
//  Copyright (c) 2015 Louis Orleans. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var chkRandomize: NSButton!
    @IBOutlet weak var txtImageFolder: NSTextField!
    @IBOutlet weak var txtInterval: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let defaults = NSUserDefaults.standardUserDefaults()
        if (defaults.objectForKey("FolderPath") != nil) {
            txtImageFolder.stringValue = defaults.objectForKey("FolderPath") as String
        }
        if (defaults.objectForKey("SwitchTime") != nil) {
            txtInterval.integerValue = defaults.objectForKey("SwitchTime") as Int
        }
        if (defaults.objectForKey("Randomize") != nil) {
            chkRandomize.state = (defaults.objectForKey("Randomize") as Bool) ? NSOnState : NSOffState
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onBtnSelect(sender: NSButton) {
        let openPanel:NSOpenPanel = NSOpenPanel()
        openPanel.nameFieldLabel = "Select wallpaper folder"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        
        if (openPanel.runModal() == NSOKButton) {
            let url = openPanel.URL?.absoluteString?.stringByReplacingOccurrencesOfString("file://", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
            txtImageFolder.stringValue = url!
        }
    }

    @IBAction func onBtnSave(sender: NSButton) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(txtImageFolder.stringValue, forKey: "FolderPath")
        defaults.setBool(chkRandomize.state == NSOnState, forKey: "Randomize")
        defaults.setInteger(txtInterval.integerValue, forKey: "SwitchTime")
        defaults.synchronize()
        
//        window.close()
        
        let wallcycle = Wallcycle()
        wallcycle.update()
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func onBtnCancel(sender: NSButton) {
        //        window.close()
        NSApplication.sharedApplication().terminate(self)
    }
}

