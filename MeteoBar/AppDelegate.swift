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
    var displayMode = 0
    var updateDisplayTimer: Timer?
    var fetchFeedTimer: Timer?
    
    func addConfigurationMenuItem() {
        let separator = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
        statusItem.menu?.addItem(separator)
    }
    
    @objc func showSettings(_ sender: NSMenuItem) {
        updateDisplayTimer?.invalidate()
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
                self.updateDisplay()
            }
        }
    }
    
    @objc func loadSettings() {
        displayMode = UserDefaults.standard.integer(forKey: "statusBarOption")
        fetchFeedTimer = Timer.scheduledTimer(timeInterval: 60 * 5, target: self, selector: #selector(fetchFeed), userInfo: nil, repeats: true)
        fetchFeedTimer?.tolerance = 60
        configureUpdateDisplayTimer()
        fetchFeed()
    }
    
    func updateDisplay() {
        guard let feed = feed else { return }
        var text = "Error"
        
        switch displayMode {
        case 0:
            if let summary = feed["currently"]["summary"].string {
                text = summary
            }
        case 1:
            if let temperature = feed["currently"]["temperature"].int {
                text = "\(temperature)"
            }
        case 2:
            if let rain = feed["currently"]["precipProbability"].double {
                text = "Rain: \(rain * 100)%"
            }
        case 3:
            if let cloud = feed["currently"]["cloudCover"].double {
                text = "Cloud: \(cloud * 100)%"
            }
        default:
            break
        }
        statusItem.button?.title = text
    }
    
    @objc func changeDisplayMode() {
        displayMode += 1
        if displayMode > 3 {
            displayMode = 0
        }
        updateDisplay()
    }
    
    func configureUpdateDisplayTimer() {
        guard let statusBarMode = UserDefaults.standard.string(forKey: "statusBarOption") else { return }
        if statusBarMode == "-1" {
            displayMode = 0
            updateDisplayTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(changeDisplayMode), userInfo: nil, repeats: true)
        } else {
            updateDisplayTimer?.invalidate()
        }
    }
}

