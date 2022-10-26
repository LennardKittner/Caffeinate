//
//  ConfigData.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import Foundation

func ==(op1: ConfigData, op2: ConfigData) -> Bool {
    return op1.atLogin == op2.atLogin && op1.hardMode == op2.hardMode
}

final class ConfigData: Decodable, Encodable {
    var hardMode :Bool
    var atLogin :Bool
    
    enum CodingKeys: CodingKey {
        case hardMode
        case atLogin
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hardMode = try container.decode(Bool.self, forKey: .hardMode)
        self.atLogin = try container.decode(Bool.self, forKey: .atLogin)
    }
    
    init() {
        hardMode = false
        atLogin = false
    }
    
    init(copy: ConfigData) {
        hardMode = copy.hardMode
        atLogin = copy.atLogin
    }
}
