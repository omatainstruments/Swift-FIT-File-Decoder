//
// Created by Julian Bleecker on 2/17/17.
// Copyright (c) 2017 OMATA. All rights reserved.
//

import Foundation

class Decode {

    func start() {
//for argument in CommandLine.arguments {
//    switch argument {
//    case "arg1":
//        print("first argument");
//
//    case "arg2":
//        print("second argument");
//
//    default:
//        print(argument);
//    }
//}

        //let path: String = "/Users/julian/Code/FitSDKRelease_20.22.00/examples/Activity.fit"
        let path: String = "/Users/julian/Desktop/170204164534.fit"


        print(path)


        let file: FileHandle? = FileHandle(forReadingAtPath: path)


        if file != nil {
            let data: Data = (file?.readDataToEndOfFile())!

            var fileSize : Int
            var attr : Dictionary<FileAttributeKey, Any>
            do {
                //return [FileAttributeKey : Any]
                attr = try FileManager.default.attributesOfItem(atPath: path)
                fileSize = attr[FileAttributeKey.size] as! Int
            } catch {
                print("Error: \(error)")
                fileSize = 0
            }

            var header: Data = data.subdata(in: Range(uncheckedBounds: (0, 14)))

            let headerSize = header.convert(to: UInt8.self, at: 0)!
            //data.convert(to: Int8.self, at: 14)
            print("header size = \(headerSize)")

            let protocolVer = header.convert(to: UInt8.self, at: 1)!


            //Range(uncheckedBounds: (2, ))
            let profileVer = header.convert(to: UInt16.self, with: 2 ..< 4)!
            print("profile ver = \(profileVer)")

            let dataSize:UInt32 = header.convert(to: UInt32.self, with: 4 ..< 8)!


            print("data size = \(dataSize)")

            let readableFIT = header.rangeToString(with: 8 ..< 12)!
            print("Ascii \(readableFIT)")


            // GET THE NEXT CRCs
            var _crc : UInt16 = 0
            if headerSize > 12 {
                _crc = header.convert(to: UInt16.self, with: 12..<14) ?? 0x0000
                if _crc == 0x0000 {
                    _crc = data.convert(to:UInt16.self, with: fileSize-2..<fileSize)!
                }
            } else {
                _crc = data.convert(to:UInt16.self, with: fileSize-2..<fileSize)!
            }

//            String(format: "0x%x", _crc)
            print("Expected CRC: \(String(format: "0x%X", _crc))")
            file?.closeFile()

            //var count = 0
            var calc_crc : UInt16 = 0
            for index:Int in 0...fileSize-3 {
                calc_crc = calcCRC(crc: calc_crc, b: data[index])
                //print("\(String(format: "%d", index)) \(String(format: "0x%01.2X", data[index])) \(String(format: "0x%01.4X", _crc))")

                // let fileManager = FileManager.default
            }
            print("Calculated CRC \(String(format: "0x%X", calc_crc))")
            print("Filesize = \(fileSize)")
            // let attributes = fileManager.attributesOfItem(atPath: path)

            struct Field_def  {
                var field_definition_number: Int
                var size: Int
                var base_type: Int
                var offset: Int //length of data (calculated using field def size) within data record preceding the data field
            }

            struct Def_message {
                var arch_is_big_endian: Bool = false
                var global_message_number: UInt16 = 0
                var number_of_fields: UInt8 = 0
                //var field_defs : [Field_def]
                var field_defs: Array<Field_def> = Array<Field_def>()
            }

            var def_message: Def_message
            //var definition = Array<Def_message>(repeating: Def_message(), count: 100)//[Def_message]()

            var definition:[Int:Def_message] = [Int:Def_message]()

            var localMsgType: UInt8
            //var glob_msg_num_0_read: Bool
            var kPosFromFileHeader: Int = 0
            let _fileHeaderSize:Int = Int(headerSize)

            for _ in 0..<(Int(dataSize)) {
                // for convenience's sake, let's have everything an Int (64-bit on OSX and iOS)

                let rHead = data[_fileHeaderSize + kPosFromFileHeader]
                print("Position From File Start \(String(format: "%d", _fileHeaderSize + kPosFromFileHeader))")
                print("Position From File Header \(kPosFromFileHeader)")
                let tmp:UInt8 = data.convert(to: UInt8.self, at: _fileHeaderSize+kPosFromFileHeader)!
                print("Byte under kPosFromFileHeader \(String(format: "0x%X", tmp))")

                // smells like old foot
                if (_fileHeaderSize + kPosFromFileHeader) >= (Int(dataSize - 2)) {
                    exit(0)
                }

                if rHead>>6 == 1 { //01000000 -> 01
                    print("Definition Message")

                    localMsgType = rHead & 0x1f

                    //get record content 4.2.1 of FIT SDK
                    //
                    // From Table 4-3 of FIT SDK
                    // Byte 0 ---- RESERVED
                    // Byte 1 ---- ARCHITECTURE (0->Little; 1->Big or False=Little, True=Big)
                    // Bytes 2-3 - GLOBAL MESSAGE NUMBER (Endianess defined by ARCHITECTURE)
                    // Byte 4 ---- Number of fields in the data message
                    // Byte 5-> -- Field Definition
                    //
                    // Onward it's Byte(4+Fields*3)
                    // And developer fields after that, which I hope we never use..

                    let archIsBigEndian = data.convert(to: Bool.self, at: _fileHeaderSize + kPosFromFileHeader + 2)!

                    // Global Message Number
                    let gmn = data.convert(to: UInt16.self, at: _fileHeaderSize + kPosFromFileHeader + 3, bigEndian: archIsBigEndian)!

                    // Number of Fields
                    let nof = data.convert(to: UInt8.self, at: _fileHeaderSize + kPosFromFileHeader + 5)!

                    def_message = Def_message(arch_is_big_endian: archIsBigEndian, global_message_number: gmn, number_of_fields: nof, field_defs: Array<Field_def>())

                    print(def_message)

                    let pos = _fileHeaderSize + kPosFromFileHeader//Int(exactly: dataSize)! - k - 1
                    print("\n[POS: \(String(format: "%d", pos ))]")
                    print("DEFINITION MESSAGE HEADER, ")
                    print("Record Header: \(String(format: "0x%X", rHead))")
                    print(" Local Message Type: \(String(format: "%d", localMsgType))")
                    print(" Global Message No: \(String(format: "%d", def_message.global_message_number))")
                    print(" No. of Fields: \(String(format: "%d", def_message.number_of_fields))")

                    let final_pos_check = pos + 3 + Int(def_message.number_of_fields * 3)
                    print("This Definition Message Should End At \(final_pos_check)")

                    // Get Field Definitions Now

                    let DEF_MSG_RECORD_HEADER_SIZE:Int = 1  // bytes
                    let DEF_MSG_FIXED_CONTENT_SIZE:Int = 5  // bytes
                    let DEF_MSG_FIELD_DEF_SIZE:Int = 3      // bytes

                    var cumulative_size: Int = 0

                    for f:Int in 0..<Int(def_message.number_of_fields) {
                        var def_contents: Field_def
                        var r_offset: Int // byte offset for file reader
                        var loc : Int
                        // 1 byte field definition number. 4.2.1.4.1 in FIT SDK
                        r_offset = 0

                        loc = _fileHeaderSize+kPosFromFileHeader+DEF_MSG_RECORD_HEADER_SIZE+DEF_MSG_FIXED_CONTENT_SIZE+(DEF_MSG_FIELD_DEF_SIZE * f)
                        let fdn = data.convert(to: UInt8.self, at: loc+r_offset)!

                        // size
                        r_offset = 1
                        let size = data.convert(to: UInt8.self, at: loc+r_offset)!

                        // base type
                        r_offset = 2
                        let baseType = data.convert(to: UInt8.self, at: loc+r_offset)!

                        // cumulative size for calculating data field offset
                        cumulative_size += Int(size)

                        def_contents = Field_def(field_definition_number: Int(fdn), size: Int(size), base_type: Int(baseType), offset: Int( cumulative_size - Int(size)))

                        //print("Field No: \(String(format: "%d\t", f))\n\tField Def. No. : \(String(format: "%d ", def_contents.field_definition_number)) \(Maps.Foo[def_contents.field_definition_number]  ?? "UNKNOWN") \(String(format: "\n\tSize: %d\n\tBase Type: %x\n\tOffset %d\n", def_contents.field_definition_number, def_contents.size, def_contents.base_type, def_contents.offset))")

                        //we will need a means of temporarily storing all the fields definition data so that it can be used to retrieve the record data later
                        def_message.field_defs.append(def_contents)
                        print(def_contents)

                    }
                    //store field definitions against local message type

                    definition[Int(localMsgType)] = def_message //of course this gets overwritten if localMsgType has been used before

                    // we will skip ahead this amount
                    // combined length of fixed and variable record content field
                    var rc_length:Int = 5 + Int(nof)*3 // record header, 5 bytes of fixed content, 3 bytes for each field definition (3 bytes/field) cf. 4.2.1 in SDK

                    kPosFromFileHeader = kPosFromFileHeader + rc_length + 1 // advance past the end of the definition record so we're pointing at the beginning of the next record, whatever it may be..
                    print("At End Of Definition Record Data Under Is \(String(format: "loc:%d (0x%X) byte:0x%X", kPosFromFileHeader+_fileHeaderSize, kPosFromFileHeader+_fileHeaderSize, data[kPosFromFileHeader+_fileHeaderSize]))")
                    print("------------------------------")
//                    for def in 0..<def_message.field_defs.count {
//                        print("\(def_message.field_defs[def])")
//                    }

//</editor-fold>
                    if kPosFromFileHeader >= Int(dataSize) {
                        break
                    }
                }
                else {  //10000000 (Data Message)
                    var compHeader:Bool = false

                    // check for compressed header
                    if rHead >> 7 == 1 { // is compressed header
                        compHeader = true
                    }
                    //set vars dependant on header type
                    if compHeader {
                        localMsgType = rHead & 0x60 >> 5 //LMT is bits 5-6

                    } else {
                        localMsgType = rHead & 0x1f //LMT is bits 0-3
                    }

                    print("\(definition[Int(localMsgType)])")
                    var global_message_number = definition[Int(localMsgType)]?.global_message_number
                    guard global_message_number != nil else {
                        print("OUCH")
                        exit(-111)
                    }

                    // 0 is little endian
                    // 1 is big endian
                    var arch = definition[Int(localMsgType)]!.arch_is_big_endian

                    //print("\n[POS: \(String(format:"%8d", Int(dataSize)-k-1))")
                    print("Data Message Header: \(String(format:"%d", rHead))")
                    print("Local Message Type: \(String(format:"%d", localMsgType))")
                    print("Global Message Number: \(global_message_number)")
                    print("Architecture (false->Little Endian): \(arch)")


                    //Here's where we extract the data from the .fit activity file and add it to our FitFile data structure'
                    kPosFromFileHeader+=1 // skip past record header
                    print("Now at -> \(_fileHeaderSize+kPosFromFileHeader)")

                    let message_def : Def_message = definition[Int(localMsgType)]!
                    let field_defs : [Field_def] = message_def.field_defs
                    let field_count = field_defs.count

                    let _def:Def_message = definition[Int(localMsgType)]!

                    // get the size of the whole data record
                    var dataRecordSize = 0
                    for i in 0..<field_count {
                        let field_def : Field_def = field_defs[i]
                        let size = field_def.size
                        dataRecordSize += size
                    }
                    print("Overall Record Size=\(dataRecordSize)")
                    switch Int(localMsgType) {

                    case 1: // file_id
                        print("\(definition[Int(localMsgType)])")
//                        let message_def : Def_message = definition[Int(localMsgType)]!
//                        let field_defs : [Field_def] = message_def.field_defs
//                        let field_count = field_defs.count

                        for fd_index in 0..<field_count {
                            let field_def : Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number
                            var index_from_zero = _fileHeaderSize+kPosFromFileHeader

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)


                            print("field def=\(field_def.field_definition_number) field name=\(Maps.Foo[field_def.field_definition_number]!) size=\(String(format: "%d", field_def.size)) base type=\(String(format: "0x%X", field_def.base_type)) index_from_zero=\(index_from_zero)")

                            switch field_definition_number {
                            case 0:
                                let file_type = data.convert(to: UInt8.self, at:index_from_zero, bigEndian: arch)

                                print("File Type \(file_type)")
                                break
                            case 1:
                                let manufacturer = data.convert(to: UInt16.self, at:index_from_zero, bigEndian: arch)
                                print("Manufacturer \(manufacturer)")
                                break
                            case 2:
                                let product = data.convert(to: UInt16.self, at:index_from_zero, bigEndian: arch)
                                print("Product ID \(product)")
                                break
                            case 3:
                                let sn = data.convert(to: UInt32.self, at:index_from_zero, bigEndian: arch)
                                print("Serial Number \(sn)")
                                break
                            case 4:
                                let tc = data.convert(to: UInt32.self, at:index_from_zero, bigEndian: arch)
                                print("Time Created \(tc)")
                                break
                            case 5:
                                let nb = data.convert(to: UInt16.self, at:index_from_zero, bigEndian: arch)
                                print("Number \(nb)")
                                break
                            case 8:
                                let range : Range = Range(uncheckedBounds: (lower: index_from_zero, upper: index_from_zero+field_def.size))
                                let name = data.rangeToString(with: range)
                                print("Name \(name)")
                                break
                            default:
                                print("DEFAULTDEFAULTDEFAULT")
                                break

                            }
                            print("skip forward by \(size)")
                            index_from_zero += Int(size)
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(index_from_zero)")
                            //print("index from zero \(index_from_zero)")

                        }
                        break


                    case 2: // Software
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 9: // Activity
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 10: // Session
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 11: // Record
                        print("RECORD")
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 12: // Event
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 21: // event
                        print(field_count)
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 23: // device info
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }

                        break

                    case 49: // file creator
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }


                        break

                    default: //
                        print("field_count \(field_count) for \(localMsgType)")
                        for fd_index in 0..<field_count {
                            let field_def: Field_def = field_defs[fd_index]
                            let size = field_def.size
                            let field_definition_number = field_def.field_definition_number

                            //print("k=\(kPosFromFileHeader)")
                            //data.convert(to: field_def.)

                            let index_from_zero = _fileHeaderSize + kPosFromFileHeader
// switch on field definition number, etc.
                            print("skip forward by \(size)")
                            kPosFromFileHeader += Int(size)
                            print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
                            print("index from zero \(index_from_zero)")

                        }


                        break


                    }

//                    print("skip forward by \(dataRecordSize)")
//                    kPosFromFileHeader += Int(dataRecordSize)
//                    print("new position from zero \(_fileHeaderSize+kPosFromFileHeader)")
//                    //print("index from zero \(index_from_zero)")



                }


            }



        }
    }


    func calcCRC(crc:UInt16, b:UInt8) -> UInt16 {
        let crc_table : [UInt16] = [0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
                                    0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400]
        let index = Int.init(Int.init(crc) & Int.init(0xf))
        var tmp : UInt16 = crc_table[index]

        var _crc = (crc >> 4) & 0x0FFF
        _crc = _crc ^ tmp ^ crc_table[Int.init(b & 0xF)]

        // now compute checksum of upper four bits of byte
        tmp = crc_table[Int.init(_crc & 0xF)]
        _crc = (_crc >> 4) & 0x0FFF
        _crc = _crc ^ tmp ^ crc_table[Int.init(b >> 4) & 0xF]

        return _crc

    }

}