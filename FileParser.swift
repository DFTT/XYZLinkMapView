//
//  FileParser.swift
//  XYZLinkMapView
//
//  Created by 大大东 on 2023/11/2.
//

import Cocoa

struct LinkMap {
    class ObjectFile {
        struct Symbol {
            let adress: String
            let size: UInt
            let fileNum: String
            let text: String
        }

        // "[ xx ]"
        let orderNumber: String
        // "xx".o / xxx("xx".o)
        let name: String
        // "xxx"(xx.o)  只有是framework中.o才有
        let frameWorkName: String?

        // # Symbols: 中的
        var symbols: [Symbol] = []
        // # Symbols: 中的size累加 Byte
        var size: UInt {
            return symbols.reduce(UInt(0)) { partialResult, sym in
                partialResult + sym.size
            }
        }

        init(orderNumber: String, name: String, frameWorkName: String?) {
            self.orderNumber = orderNumber
            self.name = name
            self.frameWorkName = frameWorkName
        }
    }

    // # Arch: arm64
    let arch: String

    // # Object files:
    let objectFiles: [String: ObjectFile]
}

enum FileParser {
    static func parse(file: URL) -> LinkMap? {
        guard let content = try? String(contentsOf: file, encoding: .utf8),
              content.isEmpty == false
        else {
            return nil
        }
        let lines = content.components(separatedBy: "\n")

        var arch = ""
        var objectFiles: [String: LinkMap.ObjectFile] = [:]

        // 标记解析到了哪个section
        var sectionIdx = 0
        for line in lines {
            let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.isEmpty == false else { continue }

            if line.hasPrefix("#") {
                // 表头跳过
                if line.hasPrefix("# Address") { continue }
                // 重置
                sectionIdx = 0
                if line.hasPrefix("# Arch:") {
                    //
                    arch = line.components(separatedBy: ":").last!
                } else if line.hasPrefix("# Object files:") {
                    // 解析name
                    sectionIdx = 1
                } else if line.hasPrefix("# Sections:") {
                    //
                } else if line.hasPrefix("# Symbols:") {
                    // 解析size
                    sectionIdx = 2
                }
                //  else if line.hasPrefix("# Dead Stripped Symbols:") {
                //    //
                //  }
                continue
            }
            autoreleasepool {
                if sectionIdx == 1 {
                    if let obj = objectFile(with: line) {
                        objectFiles[obj.orderNumber] = obj
                    }
                } else if sectionIdx == 2 {
                    if let symbol = parserSymbolSize(line: line) {
                        objectFiles[symbol.fileNum]!.symbols.append(symbol)
                    }
                }
            }
        }

        return LinkMap(arch: arch, objectFiles: objectFiles)
    }
}

extension FileParser {
    private static func objectFile(with line: String) -> LinkMap.ObjectFile? {
        guard let idx = line.firstIndex(of: "]") else { return nil }

        let number = String(line[line.startIndex ... idx])
        let name: String
        let framework: String?

        let filePath = String(line[line.index(idx, offsetBy: 1) ..< line.endIndex])
        let lastComp = (filePath as NSString).lastPathComponent
        let compArr = lastComp.components(separatedBy: "(")
        if compArr.count == 2 {
            framework = compArr.first!
            name = String(lastComp.dropLast(1))
        } else {
            framework = nil
            name = lastComp
        }

        return LinkMap.ObjectFile(orderNumber: number, name: name, frameWorkName: framework)
    }

    private static func parserSymbolSize(line: String) -> LinkMap.ObjectFile.Symbol? {
        let pattern = "(0x.+)\\s+(0x.+?)\\s+(\\[.+?\\])\\s+(.+)"
        guard let regx = try? NSRegularExpression(pattern: pattern),
              let result = regx.matches(in: line, range: NSRange(location: 0, length: line.count)).first
        else {
            print("match fail: \(line)")
            return nil
        }

        let line = line as NSString
        var sizeRange = result.range(at: 2)
        sizeRange.location += 2
        sizeRange.length -= 2
        return LinkMap.ObjectFile.Symbol(adress: line.substring(with: result.range(at: 1)),
                                         size: UInt(line.substring(with: sizeRange), radix: 16)!,
                                         fileNum: line.substring(with: result.range(at: 3)),
                                         text: line.substring(with: result.range(at: 4)))
    }
}
