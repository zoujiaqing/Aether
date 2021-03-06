//
//  Application.swift
//  Aether
//
//  Created by renan jegouzo on 13/03/2016.
//  Copyright © 2016 aestesis. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import SwiftyJSON

#if os(macOS)
    import AppKit
#elseif os(iOS) || os(tvOS)
    import UIKit
#endif

public class Application {
    #if os(macOS)
    public static var applicationDelegate : OsAppDelegate {
        return NSApplication.shared.delegate as! OsAppDelegate
    }
    #elseif os(iOS) || os(tvOS)
    public static var applicationDelegate : OsAppDelegate {
        return UIApplication.shared.delegate as! OsAppDelegate
    }
    #endif
    static var zipBundles = [ZipBundle]()
    public static let events = MultiEvent<String>()
    public static var launches : Int = 0
    public static var author:String = "aestesis"
    public static let onPause=Event<Void>()
    public static let onResume=Event<Void>()
    public static let onStop=Event<Void>()
    public static var live=[String:Any]()
    public static var db=Application()
    public static var id:String {
        return Bundle.main.bundleIdentifier!
    }
    #if os(macOS) || os(iOS) || os(tvOS)
        public static var name:String {
            return Bundle.main.infoDictionary!["CFBundleName"] as! String
        }
    #else
        public static var name:String = "unknown"
    #endif
    public static var version:String {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        #else
            return "Application.version"
        #endif
    }
    public static var build:String {
        #if os(macOS) || os(iOS) || os(tvOS)
            return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        #else
            return "Application.build"
        #endif
    }
    #if os(OSX) || os(iOS)
        public subscript(key: String) -> String? {
            get { return UserDefaults.standard.string(forKey:key) }
            set(v) { UserDefaults.standard.setValue(v,forKey:key) }
        }
        public func synchronize() {
            UserDefaults.standard.synchronize()
        }
        public func clear() {
            UserDefaults.standard.removePersistentDomain(forName: Application.id)
        }
        public private(set) var loaded = true
        init() {
            Debug.warning("application initialized")
            Device.initialize()
        }
    #else
        var def = [String:String]()
        public subscript(key: String) -> String? {
            get { return def[key] }
            set(v) { def[key] = v }
        }
        public func synchronize() {
            Application.setJSON(Application.localPath(".defaults.json"), JSON(def))
        }
        public func clear() {
            def.removeAll()
        }
        public private(set) var loaded = false
        init() {
            Debug.warning("application initialized")
            Device.initialize()
            Debug.warning("Application.db: loading")
            srand48(Int(ß.time))
            Application.getJSON(Application.localPath(".defaults.json")) { json in
                for (k,v) in json.dictionaryValue {
                    self.def[k] = v.stringValue
                }
                self.loaded = true
                Debug.warning("Application.db: loaded")
            }
        }
    #endif
    public static func initialize(name:String?=nil,codeRoot:String?=nil,assets:[String]?=nil) {
        if let codeRoot = codeRoot {
            Debug.codeRoot = codeRoot
        }
        #if os(Linux)
            if let name = name {
                Application.name = name
            }
            if let assets = assets {
                for a in assets {
                    if let f = Misc.find(file:a) {
                        if let zb = ZipBundle(path:f) {
                            zipBundles.append(zb)
                        }
                    }                    
                }                
            }
            Application.db["initialized"] = "ok"
        #endif
    }
    public func contains(key: String) -> Bool {
        if let _ = self[key] {
            return true
        }
        return false
    }
    public func json(_ key:String) -> JSON? {
        if let data = self[key] {
            let json = JSON.parse(string: data)
            return json
        }
        return nil
    }
    public func json(_ key:String,value:JSON) {
        if let text = value.rawString() {
            self[key] = text
        } else {
            Debug.error("can't convert JSON to text",#file,#line);
        }
    }
    public static func temporaryPath(_ path:String) -> String {
        let temp = FileManager.default.temporaryDirectory.path
        return "\(temp)/\(path)"
    }
    public static func homePath(_ path:String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/\(path)"
    }
    public static func localPath(_ path:String) -> String {
        #if os(OSX)
            let sup=NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationSupportDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            let dir=sup+"/"+Bundle.main.bundleIdentifier!+"/"
            let fm=FileManager.default
            if !fm.fileExists(atPath: dir) {
                do {
                    try fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    Debug.error(Error("can't create app local directory",#file,#line))
                }
            }
            return dir+path
        #elseif os(iOS)
            let dir=NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
            return dir+"/"+path
        #elseif os(tvOS)
            let dir=NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!
            return dir+"/"+path
        #else
            let fm = FileManager.default
            let sup = fm.homeDirectoryForCurrentUser.path
            let dir = "\(sup)/.aether/\(Application.name)/"
            if !fm.fileExists(atPath: dir) {
                do {
                    try fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    Debug.error("can't create app local directory")
                }
            }
            return dir+path
        #endif
    }
    public static func resourcePath(_ path:String) -> String {
        if path[0]=="/" {
            return path
        }
        #if os(macOS) || os(iOS) || os(tvOS)
            return "\(Bundle.main.resourcePath!)/\(path)"
        #else 
            return path
        #endif
    }
    public static func fileExists(_ path:String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    public static func readFile(_ path:String) -> Stream? {
        let p=Application.resourcePath(path)
        if FileManager.default.fileExists(atPath: p) {
            return FileReader(filename:p)
        } else {
            for zb in Application.zipBundles {
                if zb.contains(path) {
                    return zb.open(filename:path)
                }
            }
        }
        return nil
    }
    public static func getData(_ path:String) -> [UInt8]? {
        if let f = Application.readFile(path) {
            return f.read(f.available)
        } 
        return nil
    }
    public static func getText(_ path:String,_ fn:@escaping (String?)->()) {
        if let f = Application.readFile(path) {
            let r=UTF8Reader()
            r.onClose.once {
                if let s=r.readAll() {
                    fn(s)
                } else {
                    fn(nil)
                }
            }
            r.onError.once { err in
                fn(nil)
            }
            f.pipe(to:r)
        } else {
            fn(nil)
        }
    }
    public static func readText(_ path:String,_ fn:@escaping (UTF8Reader?)->()) {
        if let f = Application.readFile(path) {
            let r=UTF8Reader()
            f.pipe(to:r)
            fn(r)
        } else {
            fn(nil)
        }
    }
    public static func getJSON(_ path:String,_ fn:@escaping (JSON)->()) {
        if let f = Application.readFile(path) {
            let r=UTF8Reader()
            r.onClose.once {
                if let s=r.readAll() {
                    fn(JSON.parse(string: s))
                }
            }
            r.onError.once { err in
                fn(JSON.null)
            }
            f.pipe(to:r)
        } else {
            fn(nil)
        }
    }
    public static func setJSON(_ path:String,_ json:JSON) {
        let f=FileWriter(filename:path)
        let w=UTF8Writer()
        w.pipe(to:f)
        let _ = w.write(json.rawString()!)
        w.close()
    }
    public static func open(url:String)  {
        #if os(iOS)
            if let nsurl = Foundation.URL(string:url) {
                UIApplication.shared.open(nsurl)
            } else {
                Debug.error("can't open \(url) in default browser")
            }
        #elseif os(macOS)
            if let nsurl = Foundation.URL(string:url) {
                NSWorkspace.shared.open(nsurl)
            } else {
                Debug.error("can't open \(url) in default browser")
            }
        #else
            // TODO: launch shell command "gnome-open http://askubuntu.com"
            Debug.notImplemented()
        #endif
    }
    public static func stop() {
        Application.onStop.dispatch(())
        Application.live.removeAll()
        Application.db.synchronize()
        #if os(OSX)
            NSApplication.shared.terminate(nil)
        #endif
    }
    public static func pause() {
        onPause.dispatch(())
    }
    public static func resume() {
        onResume.dispatch(())
    }
}
