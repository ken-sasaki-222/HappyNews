//
//  CommentStruct.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2021/02/14.
//  Copyright © 2021 佐々木　謙. All rights reserved.
//

import Foundation

// ▼関係するclass
// TimeLineCommentViewController

// コメント投稿で扱う構造体
struct CommentStruct {
    
    let sender     : String
    let comment    : String
    let aiconImage : String
    let userName   : String
    let createdTime: String
    let documentID : String
}
