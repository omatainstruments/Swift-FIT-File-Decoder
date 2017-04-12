//
// Created by Julian Bleecker on 2/18/17.
// Copyright (c) 2017 OMATA. All rights reserved.
//

import Foundation

class Maps {


    //func Product(id:Int)

    class func Global_message_type(id:UInt8) -> String {
        //var global_message_type = Array<String>()//= make(map[uint16]string)
        var global_message_type = Array(repeating: "", count: Int(UInt8.max))

        global_message_type[Int(id)] = "UNKNOWN GLOBAL MESSAGE TYPE ID=" + String(id)//strconv.Itoa(int(id))

        global_message_type[0] = "FILE_ID"
        global_message_type[18] = "SESSION"
        global_message_type[19] = "LAP"
        global_message_type[20] = "RECORD"
        global_message_type[21] = "EVENT"
        global_message_type[23] = "DEVICE_INFO"
        global_message_type[34] = "ACTIVITY"
        global_message_type[49] = "FILE_CREATOR"

        return global_message_type[Int(id)]
    }


    class var Foo : [Int:String] {
        get {
            return [
                    0: "type",
                    1: "manufacturer",
                    2: "product",
                    3: "serial_number",
                    4: "time_created",
                    5: "number",
                    8: "product_name"
            ]
        }
    }

    class var Types: [Int:Any] {
        get {
            return [
                    1:Int8.self

            ]
        }
    }


}