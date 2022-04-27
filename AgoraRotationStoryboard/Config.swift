//
//  Config.swift
//  AgoraRotationStoryboard
//
//  Created by shaun on 4/27/22.
//

import Foundation


func configValue<T>(for key: String) throws -> T where T: LosslessStringConvertible {
   guard let object = Bundle.main.object(forInfoDictionaryKey:key) else {
       fatalError("No value for Config Key")
   }

   switch object {
   case let value as T:
       return value
   case let string as String:
       guard let value = T(string) else { fallthrough }
       return value
   default:
       fatalError("Config Key is not a string")
   }
}
