//
//  AppDelegate.swift
//  MeteoBar
//
//  Created by Emir SARI on 30.09.2019.
//  Copyright © 2019 Emir SARI. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var feed: JSON?
    
    func addConfigurationMenuItem() {
        let separator = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
        statusItem.menu?.addItem(separator)
    }
    
    @objc func showSettings(_ sender: NSMenuItem) {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "ViewController") as? ViewController else { return }
        let popoverView = NSPopover()
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        popoverView.show(relativeTo: statusItem.button!.bounds, of: statusItem.button!, preferredEdge: .maxX)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let defaultSettings = ["latitude": "51.507222", "longitude": "-0.1275", "apiKey": "", "statusBarOption": "-1", "units": "0"]
        UserDefaults.standard.register(defaults: defaultSettings)
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(loadSettings), name: Notification.Name("SettingsChanged"), object: nil)
        statusItem.button?.title = "Fetching..."
        statusItem.menu = NSMenu()
        addConfigurationMenuItem()
        loadSettings()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    @objc func fetchFeed() {
        let defaults = UserDefaults.standard
        guard let apiKey = defaults.string(forKey: "apiKey") else { return }
        guard !apiKey.isEmpty else {
            statusItem.button?.title = "No API Key"
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [unowned self] in
            let latitude = defaults.double(forKey: "latitude")
            let longitude = defaults.double(forKey: "longitude")
            
            var dataSource = "https://api.darksky.net/forecast/\(apiKey)\(latitude),\(longitude)"
            
            if defaults.integer(forKey: "units") == 0 {
                dataSource += "?units=si"
            }
            
            guard let url = URL(string: dataSource) else { return }
            guard let data = try? String(contentsOf: url) else {
                DispatchQueue.main.async { [unowned self] in
                    self.statusItem.button?.title = "Bad API call"
                }
                return
            }
            
            
            let newFeed = JSON(parseJSON: data)
            DispatchQueue.main.async {
                self.feed = newFeed
            }
        }
    }
    
    @objc func loadSettings() {
        fetchFeed()
    }
}

