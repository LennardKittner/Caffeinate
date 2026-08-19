//
//  ConfigData.swift
//  Caffeinate
//
//  Created by Lennard on 26.10.22.
//

import Foundation

func ==(op1: ConfigData, op2: ConfigData) -> Bool {
    return op1.atLogin == op2.atLogin
        && op1.hardMode == op2.hardMode
        && op1.preventDisplaySleep == op2.preventDisplaySleep
        && op1.preventIdleSleep == op2.preventIdleSleep
        && op1.preventDiskIdle == op2.preventDiskIdle
        && op1.preventSystemSleep == op2.preventSystemSleep
        && op1.timerEnabled == op2.timerEnabled
        && op1.timerDuration == op2.timerDuration
}

final class ConfigData: Decodable, Encodable {
    var hardMode :Bool
    var atLogin :Bool
    // The following mirror the caffeinate(8) assertion flags. Defaults match
    // `caffeinate -dims`: prevent display (-d), idle (-i), disk (-m) and
    // system (-s) sleep.
    var preventDisplaySleep :Bool // -d
    var preventIdleSleep :Bool    // -i
    var preventDiskIdle :Bool     // -m
    var preventSystemSleep :Bool  // -s
    // Optional auto-off countdown: when enabled, activation turns itself off
    // after timerDuration seconds.
    var timerEnabled :Bool
    var timerDuration :TimeInterval // seconds

    enum CodingKeys: CodingKey {
        case hardMode
        case atLogin
        case preventDisplaySleep
        case preventIdleSleep
        case preventDiskIdle
        case preventSystemSleep
        case timerEnabled
        case timerDuration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hardMode = try container.decode(Bool.self, forKey: .hardMode)
        self.atLogin = try container.decode(Bool.self, forKey: .atLogin)
        // decodeIfPresent keeps older config files (which lack these keys) working.
        self.preventDisplaySleep = try container.decodeIfPresent(Bool.self, forKey: .preventDisplaySleep) ?? true
        self.preventIdleSleep = try container.decodeIfPresent(Bool.self, forKey: .preventIdleSleep) ?? true
        self.preventDiskIdle = try container.decodeIfPresent(Bool.self, forKey: .preventDiskIdle) ?? true
        self.preventSystemSleep = try container.decodeIfPresent(Bool.self, forKey: .preventSystemSleep) ?? true
        self.timerEnabled = try container.decodeIfPresent(Bool.self, forKey: .timerEnabled) ?? false
        self.timerDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .timerDuration) ?? (60 * 60)
    }

    init() {
        hardMode = false
        atLogin = false
        preventDisplaySleep = true
        preventIdleSleep = true
        preventDiskIdle = true
        preventSystemSleep = true
        timerEnabled = false
        timerDuration = 60 * 60 // default: 1 hour
    }

    init(copy: ConfigData) {
        hardMode = copy.hardMode
        atLogin = copy.atLogin
        preventDisplaySleep = copy.preventDisplaySleep
        preventIdleSleep = copy.preventIdleSleep
        preventDiskIdle = copy.preventDiskIdle
        preventSystemSleep = copy.preventSystemSleep
        timerEnabled = copy.timerEnabled
        timerDuration = copy.timerDuration
    }
}
