//
//  NSData+Convert.swift
//  rxbt-test
//
//  Created by Julian Bleecker on 2/6/17.
//  Copyright © 2017 OMATA. All rights reserved.
//

import Foundation

extension Data {


    func convert<T>(to: T.Type, at offset:Int) -> T? {
        return convert(to: to, at: offset, bigEndian: false)
    }

    func convert<T>(to: T.Type, at offset:Int, bigEndian big:Bool) -> T? {

        guard self.count+offset >= MemoryLayout<T>.size else { return nil  }

        let count = 1 // number of T.Type
        let stride = MemoryLayout<T>.stride
        let alignment = MemoryLayout<T>.alignment
        let byteCount = count * stride
        let _data = self.subdata(in: Range(uncheckedBounds: (offset, offset+stride)))
        let placeholder = UnsafeMutableRawPointer.allocate(bytes: byteCount, alignedTo:alignment)
        _data.withUnsafeBytes{(bytes: UnsafePointer<Int8>)->Void in
            for (index, byte) in _data.enumerated() {
                // endianess
                var end_index = index

                if(big) {
                    end_index = byteCount - index - 1
                }
                //print("byte[\(end_index)]->\(String(format: "0x%02x",byte)) data[\(end_index)]->\(String(format: "0x%02x", _data[end_index])) addr: \(end_index)")
                //print("\(byteCount-index-1)")
                placeholder.storeBytes(of: byte, toByteOffset: end_index, as: UInt8.self)
                //print(placeholder)
            }
        }

        let typedPointer1 = placeholder.bindMemory(to: T.self, capacity: count)
        //print("u32: \(String(format: "0x%08x", typedPointer1.pointee))")
        return typedPointer1.pointee
    }

    func convert<T>(to: T.Type, with range:Range<Int>) -> T? {
        return convert(to: to, with: range, bigEndian: false)
    }

    func convert<T>(to: T.Type, with range:Range<Int>, bigEndian big:Bool) -> T? {

        guard self.count+range.upperBound >= MemoryLayout<T>.size else { return nil  }

        let count = 1 // number of T.Type
        let stride = MemoryLayout<T>.stride
        let alignment = MemoryLayout<T>.alignment
        let byteCount = count * stride
        let _data = self.subdata(in: Range(uncheckedBounds: (range.lowerBound, range.lowerBound+stride)))
        let placeholder = UnsafeMutableRawPointer.allocate(bytes: byteCount, alignedTo:alignment)

        _data.withUnsafeBytes{(bytes: UnsafePointer<Int8>)->Void in
            for (index, byte) in _data.enumerated() {
                // endianess
                var end_index = index

                if(big) {
                    end_index = byteCount - index - 1
                }
                //print("byte[\(index)]->\(String(format: "0x%02x",byte)) data[\(index)]->\(String(format: "0x%02x", _data[index])) addr: \(index)")

                placeholder.storeBytes(of: byte, toByteOffset: end_index, as: UInt8.self)
            }
        }

        let typedPointer1 = placeholder.bindMemory(to: T.self, capacity: count)
        //print("u32: \(String(format: "0x%08x", typedPointer1.pointee))")
        return typedPointer1.pointee
    }

    // convert a range of characters to a string
    func rangeToString(with range:Range<Int>) -> String? {

        return String(data: self.subdata(in: range), encoding: .utf8)

//        for c in range.lowerBound..<range.upperBound {
//            //guard c != nil else {continue}
//            //guard self[c] != nil else { continue }
//            let x = self.convert(to: UInt8.self, at: c)
//
//            result.append(self.convert(to: Character.self, at: c)!)
//        }
//        return result
    }
}
