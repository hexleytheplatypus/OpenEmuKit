// Copyright (c) 2022, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the OpenEmu Team nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation
import AudioToolbox
import OpenEmuBase
import OpenEmuSystem

public typealias StartupCompletionHandler = (Error?) -> Void

@objc public class GameCoreManager: NSObject {
    @objc public private(set) var startupInfo: OEGameStartupInfo
    @objc public private(set) weak var plugin: OECorePlugin?
    @objc public private(set) weak var systemPlugin: OESystemPlugin?
    @objc public private(set) weak var gameCoreOwner: OEGameCoreOwner?
    
    @objc public init(startupInfo: OEGameStartupInfo, corePlugin plugin: OECorePlugin, systemPlugin: OESystemPlugin, gameCoreOwner: OEGameCoreOwner) {
        self.startupInfo    = startupInfo
        self.plugin         = plugin
        self.systemPlugin   = systemPlugin
        self.gameCoreOwner  = gameCoreOwner
    }
    
    public override var description: String {
        String(format: "<%@ %p, ROM: %@, Core: %@, System: %@, Display Helper: %@>",
               "\(Self.self)",
               Unmanaged.passUnretained(self).toOpaque().debugDescription,
               startupInfo.romPath,
               plugin?.bundleIdentifier ?? "no plugin",
               systemPlugin?.systemIdentifier ?? "no systemPlugin",
               gameCoreOwner != nil ? Unmanaged.passUnretained(gameCoreOwner!).toOpaque().debugDescription : "no gameCoreOwner"
        )
    }
    
    // MARK: - Abstract methods that must be overridden in subclasses
    
    func stop() {
        fatalError("Not implemented")
    }
    
    @objc public func loadROM(completionHandler: @escaping () -> Void, errorHandler: @escaping (Error) -> Void) {
        fatalError("Not implemented")
    }
    
    public func loadROM(completionHandler: @escaping StartupCompletionHandler) {
        fatalError("Not implemented")
    }
    
    // MARK: - Internal APIs
    
    var gameCoreHelper: OEGameCoreHelper?
    
    /// Asynchronously sends the -gameCoreDidTerminate message to the
    /// gameCoreOwner
    func notifyGameCoreDidTerminate() {
        RunLoop.main.perform { [weak self] in
            self?.gameCoreOwner?.gameCoreDidTerminate?()
        }
    }
}

extension GameCoreManager: OEGameCoreHelper {
    public func setVolume(_ value: Float) {
        gameCoreHelper?.setVolume(value)
    }
    
    public func setPauseEmulation(_ pauseEmulation: Bool) {
        gameCoreHelper?.setPauseEmulation(pauseEmulation)
    }
    
    public func setEffectsMode(_ mode: OEGameCoreEffectsMode) {
        gameCoreHelper?.setEffectsMode(mode)
    }
    
    public func setAudioOutputDeviceID(_ deviceID: AudioDeviceID) {
        gameCoreHelper?.setAudioOutputDeviceID(deviceID)
    }
    
    public func setAdaptiveSyncEnabled(_ enabled: Bool) {
        gameCoreHelper?.setAdaptiveSyncEnabled(enabled)
    }
    
    public func setCheat(_ cheatCode: String, withType type: String, enabled: Bool) {
        gameCoreHelper?.setCheat(cheatCode, withType: type, enabled: enabled)
    }
    
    public func setDisc(_ discNumber: UInt) {
        gameCoreHelper?.setDisc(discNumber)
    }

    public func insertFile(at url: URL, completionHandler block: @escaping (Bool, Error?) -> Void) {
        // we force unwrap, to ensure we panic, as the block will never be called
        gameCoreHelper!.insertFile(at: url) { success, error in
            RunLoop.main.perform {
                block(success, error)
            }
        }
    }

    public func changeDisplay(withMode displayMode: String) {
        gameCoreHelper?.changeDisplay(withMode: displayMode)
    }

    public func setOutputBounds(_ rect: NSRect) {
        gameCoreHelper?.setOutputBounds(rect)
    }

    public func setBackingScaleFactor(_ newBackingScaleFactor: CGFloat) {
        gameCoreHelper?.setBackingScaleFactor(newBackingScaleFactor)
    }

    public func setShaderURL(_ url: URL, parameters: [String: NSNumber]?, completionHandler block: @escaping (Error?) -> Void) {
        // we force unwrap, to ensure we panic, as the block will never be called
        gameCoreHelper!.setShaderURL(url, parameters: parameters) { error in
            RunLoop.main.perform {
                block(error)
            }
        }
    }
    
    public func setShaderParameterValue(_ value: CGFloat, forKey key: String) {
        gameCoreHelper?.setShaderParameterValue(value, forKey: key)
    }
    
    public func setupEmulation(completionHandler handler: @escaping (_ screenSize: OEIntSize, _ aspectSize: OEIntSize) -> Void) {
        // we force unwrap, to ensure we panic, as the block will never be called
        gameCoreHelper!.setupEmulation { screenSize, aspectSize in
            RunLoop.main.perform {
                handler(screenSize, aspectSize)
            }
        }
    }
    
    public func startEmulation(completionHandler handler: @escaping () -> Void) {
        gameCoreHelper!.startEmulation {
            RunLoop.main.perform(handler)
        }
    }
    
    public func resetEmulation(completionHandler handler: @escaping () -> Void) {
        gameCoreHelper!.resetEmulation {
            RunLoop.main.perform(handler)
        }
    }
    
    public func stopEmulation(completionHandler handler: @escaping () -> Void) {
        gameCoreHelper!.stopEmulation {
            RunLoop.main.perform {
                handler()
                self.stop()
            }
        }
    }
    
    public func saveStateToFile(atPath fileName: String, completionHandler block: @escaping (Bool, Error?) -> Void) {
        gameCoreHelper!.saveStateToFile(atPath: fileName) { success, error in
            RunLoop.main.perform {
                block(success, error)
            }
        }
    }
    
    public func loadStateFromFile(atPath fileName: String, completionHandler block: @escaping (Bool, Error?) -> Void) {
        gameCoreHelper!.loadStateFromFile(atPath: fileName) { success, error in
            RunLoop.main.perform {
                block(success, error)
            }
        }
    }
    
    public func captureOutputImage(completionHandler block: @escaping (NSBitmapImageRep) -> Void) {
        gameCoreHelper!.captureOutputImage { image in
            RunLoop.main.perform {
                block(image)
            }
        }
    }
    
    public func captureSourceImage(completionHandler block: @escaping (NSBitmapImageRep) -> Void) {
        gameCoreHelper!.captureSourceImage { image in
            RunLoop.main.perform {
                block(image)
            }
        }
    }

    public func handleMouseEvent(_ event: OEEvent) {
        gameCoreHelper?.handleMouseEvent(event)
    }
    
    public func setHandleEvents(_ handleEvents: Bool) {
        gameCoreHelper?.setHandleEvents(handleEvents)
    }
    
    public func setHandleKeyboardEvents(_ handleKeyboardEvents: Bool) {
        gameCoreHelper?.setHandleKeyboardEvents(handleKeyboardEvents)
    }
    
    public func systemBindingsDidSetEvent(_ event: OEHIDEvent, forBinding bindingDescription: OEBindingDescription, playerNumber: UInt) {
        gameCoreHelper?.systemBindingsDidSetEvent(event, forBinding: bindingDescription, playerNumber: playerNumber)
    }
    
    public func systemBindingsDidUnsetEvent(_ event: OEHIDEvent, forBinding bindingDescription: OEBindingDescription, playerNumber: UInt) {
        gameCoreHelper?.systemBindingsDidUnsetEvent(event, forBinding: bindingDescription, playerNumber: playerNumber)
    }
}

// MARK: - Synchronous image capture APIs

import Atomics

@objc extension GameCoreManager {
    public func captureOutputImage() -> NSBitmapImageRep {
        let done = ManagedAtomic(false)
        
        var res: NSBitmapImageRep?
        gameCoreHelper!.captureOutputImage(completionHandler: { image in
            RunLoop.main.perform {
                res = image
                done.store(true, ordering: .sequentiallyConsistent)
            }
        })
        
        while done.load(ordering: .sequentiallyConsistent) == false {
            if CFRunLoopRunInMode(.defaultMode, 10.0, false) == .finished {
                break
            }
        }
        
        return res!
    }
    
    public func captureSourceImage() -> NSBitmapImageRep {
        let done = ManagedAtomic(false)
        
        var res: NSBitmapImageRep?
        gameCoreHelper!.captureSourceImage(completionHandler: { image in
            RunLoop.main.perform {
                res = image
                done.store(true, ordering: .sequentiallyConsistent)
            }
        })
        
        while done.load(ordering: .sequentiallyConsistent) == false {
            if CFRunLoopRunInMode(.defaultMode, 10.0, false) == .finished {
                break
            }
        }
        
        return res!
    }
}
