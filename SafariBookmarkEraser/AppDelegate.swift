//
//  AppDelegate.swift
//  SafariBookmarkEraser
//
//  Created by gikoha on 2022/03/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var vc: ViewController!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

