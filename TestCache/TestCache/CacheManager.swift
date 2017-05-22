//
//  CacheManager.swift
//  TestCache
//
//  Created by Thomas on 5/21/17.
//  Copyright © 2017 Thomas. All rights reserved.
//

import Foundation

class AppUtil {
    static func AppExit(message: String) -> Never {
        print(message)
        return exit(0)
    }
}

class CacheFile {
    var key: String!
    var url: String!
    var lastVisit: Int!
    var fileSize: Int!
    init(key: String, url: String) {
        self.key = key
        self.url = url
        self.lastVisit = Int(Date().timeIntervalSince1970)
        self.fileSize = 100
    }
    
    func getDictionaryValue() -> [Any] {
        return [self.key, self.url, self.lastVisit, self.fileSize]
    }
    
    init(values: [Any]) {
        self.key = values[0] as! String
        self.url = values[1] as! String
        self.lastVisit = values[2] as! Int
        self.fileSize = values[3] as! Int
    }
}


class CacheManager {
    
    static let shared = CacheManager()
    let cacheBasePath: String!
    let fileManager = FileManager.default
    
    init() {
        cacheBasePath = CacheManager.getCachePath()
    }
    
    //web url 映射为 本地 url
    func getCacheFilePath() -> String? {
        return ""
    }
    
    private static func getCachePath() -> String {
    
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        if paths.count == 1{
            
        }
        let cachePath = paths[0] + "/LessonContents"
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: cachePath, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return cachePath
            }
            AppUtil.AppExit(message: "cache path is a file")
        } else {
            do {
                try FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: false, attributes: nil)
                return cachePath
            } catch {
                AppUtil.AppExit(message: error.localizedDescription)
            }
        }
    }
    
    func getCacheFilePath(fileName: String) -> String {
        return cacheBasePath + "/" + fileName
    }
    
    func fileExist(filePath: String) -> Bool {
        if fileManager.fileExists(atPath: filePath) {
            return true
        }
        return false
    }
    
    func listCacheFiles() -> [String] {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cacheBasePath)
            return contents
        } catch {
            print(error)
            return [String]()
        }
    }
    
    
    //总共有多少字节
    func getCacheFileTotalSize() -> UInt64 {
        let contents = listCacheFiles()
        var size: UInt64 = 0
        for content in contents {
            let path = getCacheFilePath(fileName: content)
            print(path)
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let temp = attributes[FileAttributeKey.size] as! NSNumber
                size += temp.uint64Value
            } catch {
                print("error attributes \(path) \(error)")
            }
        }
        return size
    }
    
    func clearAllCache(progress: (_ removedFileSize: UInt64) -> ()) {
        let contents = listCacheFiles()
        for content in contents {
            let path = getCacheFilePath(fileName: content)
            do {
                let attributes = try fileManager.attributesOfItem(atPath: path)
                let temp = attributes[FileAttributeKey.size] as! NSNumber
                try fileManager.removeItem(atPath: path)
                progress(temp.uint64Value)
            } catch {
                print("error attributes \(path) \(error)")
            }
        }
    }
    
    //如果在缓存中找到该文件，则返回缓存Url，否则返回原始Url
    func getRealUrl(url: String, key: String) -> (realURL: URL?, saveURL: URL?) {
        let path = getCacheFilePath(fileName: key)
        let fileURL = NSURL.fileURL(withPath: path)
        if fileExist(filePath: path) {
            return (fileURL, fileURL)
        }
        return (nil, fileURL)
    }
}
