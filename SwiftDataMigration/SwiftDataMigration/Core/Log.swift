//
//  Log.swift
//  SwiftDataMigration
//
import Foundation

struct Log {
    static func debug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
#if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[DEBUG] \(fileName):\(line) \(function) - \(message())")
#endif
    }
}
