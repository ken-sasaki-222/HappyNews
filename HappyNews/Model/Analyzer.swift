//
//  AnalyzerResult.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2020/10/25.
//  Copyright © 2020 佐々木　謙. All rights reserved.
//

import Foundation

struct Analyzer: Codable {
    
    var firstScore     : Float?
//    var secondScore    : Float?
//    var thirdScore     : Float?
    var firstToneName  : String?
//    var secondToneName : String?
//    var thirdToneName  : String?
    
    //構造体の初期化
    init(firstScore: Float?, firstToneName:String?) {
        
        self.firstScore     = firstScore
//        self.secondScore    = secondScore
//        self.thirdScore     = thirdScore
        
        self.firstToneName  = firstToneName
//        self.secondToneName = secondToneName
//        self.thirdToneName  = thirdToneName
    }
}
