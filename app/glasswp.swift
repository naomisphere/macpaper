#!/usr/bin/env swift
// glasswp.swift

import Cocoa
import AVKit

class macpaper_w: NSApplication {
    override func activate(ignoringOtherApps: Bool) {
        super.activate(ignoringOtherApps: true)
    }
    
    override func terminate(_ sender: Any?) {
        (NSApp.delegate as? AppDelegate)?.cleanup()
        super.terminate(sender)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var wp_service: glasswp?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return false
    }
    func cleanup() {
        wp_service?.cleanup()
    }
}

class glasswp: NSObject {
    var player: AVPlayer?
    var player_layer: AVPlayerLayer?
    var window: NSWindow?
    var gifView: NSImageView?
    var gif_img: [NSImage] = []
    var gif_cur_frame = 0
    var gif_timer: Timer?
    var wallpaper_file: String
    var cur_vol: Float = 0.5
    var isActive = true
    var transitionView: NSView?
    var transitionTimer: Timer?
    
    init(wallpaper_file: String) {
        self.wallpaper_file = wallpaper_file
        super.init()
        main()
        
        let _fe = (wallpaper_file as NSString).pathExtension.lowercased()
        
        if _fe == "gif" {
            g_gif(wallpaper_file: wallpaper_file)
        } else if ["mp4", "mov"].contains(_fe) {
            load_video(wallpaper_file: wallpaper_file)
        } else {
            print("\(_fe) is not in a valid format.")
            exit(1)
        }

        setupVolumeNotifications()
        
        x_apply_vol()
    }
    
    private func setupVolumeNotifications() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.naomisphere.macpaper.volumeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let volume = notification.userInfo?["volume"] as? Float {
                print("[glasswp] Received volume notification: \(volume)")
                self?.cur_vol = volume
                self?.x_apply_vol()
            }
        }
        print("[glasswp] listening for notifications")
    }

    func main() {
    let screen_frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    
    window = NSWindow(contentRect: screen_frame,
                     styleMask: .borderless,
                     backing: .buffered,
                     defer: false)
    
    guard let window = window else {
        print("[glasswp] error: couldn't create window")
        return
    }
    
    window.backgroundColor = NSColor.clear
    window.isOpaque = false
    window.hasShadow = false

    // this is essentially the core of the so-called "wallpaper"
    // we need the window to be behind desktop. else it would just be a
    // video player in fullscreen.
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
    window.collectionBehavior = [.stationary, .canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]
    window.ignoresMouseEvents = true
    window.isReleasedWhenClosed = false
    
    window.collectionBehavior.insert(.fullScreenNone)
    
    let contentView = NSView(frame: screen_frame)
    contentView.wantsLayer = true
    contentView.layer?.backgroundColor = NSColor.clear.cgColor
    window.contentView = contentView
    
    print("[glasswp] window created")
}
    
    func g_gif(wallpaper_file: String) {
        guard let image = NSImage(contentsOfFile: wallpaper_file) else {
            print("couldn't load gif: \(wallpaper_file)")
            return
        }

        gifView = NSImageView(frame: window?.contentView?.bounds ?? NSRect.zero)
        gifView?.imageScaling = .scaleAxesIndependently
        window?.contentView?.addSubview(gifView!)

        gifView?.image = image
        
        if let reps = image.representations as? [NSBitmapImageRep] {
            for rep in reps {
                if let cgImage = rep.cgImage {
                    gif_img.append(NSImage(cgImage: cgImage, size: .zero))
                }
            }
        }

        if gif_img.count > 1 {
            gif_init()
        }
    }
    
    func gif_init() {
        gif_timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.gif_cur_frame < self.gif_img.count {
                self.gifView?.image = self.gif_img[self.gif_cur_frame]
                self.gif_cur_frame = (self.gif_cur_frame + 1) % self.gif_img.count
            }
        }
    }
    
    func load_video(wallpaper_file: String) {
        let url = URL(fileURLWithPath: wallpaper_file)
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer(playerItem: playerItem)
        player?.actionAtItemEnd = .none
        
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            let videoSize = CGSize(width: abs(size.width), height: abs(size.height))
            
            if videoSize.width >= 3840 || videoSize.height >= 2160 {
                playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
            }
        }
        
        player_layer = AVPlayerLayer(player: player)
        player_layer?.frame = window?.contentView?.bounds ?? NSRect.zero
        player_layer?.videoGravity = .resizeAspectFill
        player_layer?.backgroundColor = NSColor.clear.cgColor

        window?.contentView?.layer = player_layer
        window?.contentView?.wantsLayer = true

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
            self?.player?.seek(to: CMTime.zero)
            self?.player?.play()
        }
        
        player?.play()
        x_load_apply_vol()
    }
    
    func x_load_apply_vol() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let volumeFile = homeDir.appendingPathComponent(".local/share/macpaper/volume")
        
        print("[glasswp] fetching volume from: \(volumeFile.path)")
        
        if FileManager.default.fileExists(atPath: volumeFile.path) {
            do {
                let volumeString = try String(contentsOf: volumeFile, encoding: .utf8)
                if let volumeInt = Int(volumeString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    let pr_vol = max(0, min(100, volumeInt))
                    let oldVolume = cur_vol
                    cur_vol = Float(pr_vol) / 100.0
                    x_apply_vol()
                    print("[glasswp] volume updated: \(Int(oldVolume * 100))% -> \(pr_vol)%")
                } else {
                    cur_vol = 0.5
                    x_apply_vol()
                }
            } catch {
                cur_vol = 0.5
                x_apply_vol()
            }
        } else {
            cur_vol = 0.5
            x_apply_vol()
        }
    }
    
    func x_apply_vol() {
        if let player = player {
            player.volume = cur_vol
        } else {
            print("[glasswp] warning: no player to apply volume to")
        }
    }
    
    func upd_vol() {
        print("[glasswp] volume update request")
        x_load_apply_vol()
    }
    
        func show() {
        guard let window = window else {
            return
        }
        
        window.alphaValue = 0.0
        window.orderBack(nil)
        window.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.8
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1.0
        }
    }
    
    func hide(completion: (() -> Void)? = nil) {
        guard let window = window else {
            completion?()
            return
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0.0
        } completionHandler: {
            window.orderOut(nil)
            self.player?.pause()
            self.gif_timer?.invalidate()
            completion?()
        }
    }
    
    func cleanup() {
        print("[glasswp] cleaning up resources")
        isActive = false
        
        hide {
            self.gif_timer?.invalidate()
            self.gif_timer = nil
            self.player?.pause()
            self.player = nil
            self.player_layer?.removeFromSuperlayer()
            self.player_layer = nil
            self.window?.orderOut(nil)
            self.window = nil
            DistributedNotificationCenter.default().removeObserver(self)
        }
    }
}

if CommandLine.arguments.count < 2 {
    print("glasswp\nUsage: \(CommandLine.arguments[0]) [ FILE ]")
    exit(1)
}

let wallpaper_file = CommandLine.arguments[1]
print("[glasswp] starting with file: \(wallpaper_file)")
print("[glasswp] started with PID: \(ProcessInfo.processInfo.processIdentifier)")

let app = macpaper_w.shared
let delegate = AppDelegate()
app.delegate = delegate

let wallpaper = glasswp(wallpaper_file: wallpaper_file)
delegate.wp_service = wallpaper

signal(SIGINT) { _ in
    print("[glasswp] Received SIGINT, exiting gracefully")
    DispatchQueue.main.async {
        NSApp.terminate(nil)
    }
}

signal(SIGTERM) { _ in
    print("[glasswp] Received SIGTERM, exiting gracefully")
    DispatchQueue.main.async {
        NSApp.terminate(nil)
    }
}

/*
var globalWallpaper: glasswp? = wallpaper

let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
source.setEventHandler {
    print("[glasswp] received SIGUSR1 (volume signal)")
    globalWallpaper?.upd_vol()
}
source.resume()
signal(SIGUSR1, SIG_IGN)
*/

wallpaper.show()

app.setActivationPolicy(.accessory)
app.run()
