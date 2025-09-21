//
// Updater.swift
//
// Created on September 21, 2025
// naomisphere
//

import Foundation
import Combine
import AppKit

class Updater: ObservableObject {
    @Published var updateAvailable = false
    @Published var isUpdating = false
    @Published var updateError: String?
    @Published var latestVersion: String?
    
    private let latestVersionURL = URL(string: "https://raw.githubusercontent.com/naomisphere/macpaper/tb/latest")!
    
    func checkForUpdates() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return
        }
        
        URLSession.shared.dataTask(with: latestVersionURL) { data, response, error in
            if let error = error {
                print("updater failed: \(error)")
                return
            }
            
            guard let data = data, 
                  let latestVersion = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                return
            }
            
            DispatchQueue.main.async {
                self.latestVersion = latestVersion
                self.updateAvailable = latestVersion != currentVersion
                
                if self.updateAvailable {
                    self.showUpdatePrompt()
                }
            }
        }.resume()
    }
    
    private func showUpdatePrompt() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Update Available"
            alert.informativeText = "A new version (\(self.latestVersion ?? "latest")) is available. Would you like to update now?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Update")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                self.do_update()
            }
        }
    }
    
    func do_update() {
        isUpdating = true
        
        let appPath = Bundle.main.bundlePath
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            updateError = "Could not get app version information"
            isUpdating = false
            return
        }
        
        let resourcesPath = "\(appPath)/Contents/Resources"
        let updaterScript = "\(resourcesPath)/.updater.sh"
        
        let process = Process()
        process.launchPath = updaterScript
        process.arguments = [currentVersion, resourcesPath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        process.terminationHandler = { process in
            DispatchQueue.main.async {
                self.isUpdating = false
                if process.terminationStatus == 0 {
                    self.show_reopen_prompt()
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                    self.updateError = output
                }
            }
        }
        
        do {
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: updaterScript)
            try process.run()
        } catch {
            updateError = error.localizedDescription
            isUpdating = false
        }
    }
    
    private func show_reopen_prompt() {
        let alert = NSAlert()
        alert.messageText = "Update Completed"
        alert.informativeText = "Update has been installed successfully. Please restart macpaper."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            self.reopen_app_after_upd()
        }
    }
    
    private func reopen_app_after_upd() {
        let appPath = Bundle.main.bundlePath
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [appPath]

        NSApplication.shared.terminate(nil)
        
        do {
            try process.run()
        } catch {
            print("while restarting: \(error)")
        }
    }
}