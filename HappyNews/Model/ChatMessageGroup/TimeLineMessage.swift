//
//  TimeLineMessage.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2021/02/04.
//  Copyright © 2021 佐々木　謙. All rights reserved.
//

import Foundation

// ▼関係するclass
// ChatViewController


// Firestoreのドキュメントに保存された値の保存で扱う
struct TimeLineMessage {
    
    let sender    : String
    let body      : String
    let aiconImage: String
    let userName  : String
}
