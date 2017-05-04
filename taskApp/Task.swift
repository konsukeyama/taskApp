//
//  Task.swift
//  taskApp
//
//  Created by Tatsunori Watabe on 2017/05/02.
//  Copyright © 2017年 konsukeyama. All rights reserved.
//

import RealmSwift

class Task: Object {
    // プライマリキー
    dynamic var id = 0
    
    // カテゴリ
    dynamic var category = ""

    // タイトル
    dynamic var title = ""
    
    // 内容
    dynamic var contents = ""
    
    // 日時
    dynamic var date = NSDate()
    
    // id をプライマリキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
