//
//  Category.swift
//  taskApp
//
//  Created by Tatsunori Watabe on 2017/05/04.
//  Copyright © 2017年 konsukeyama. All rights reserved.
//

import RealmSwift

class Category: Object {
    // プライマリキー
    dynamic var id = 0
    
    // カテゴリ名
    dynamic var name = ""
    
    // id をプライマリキーとして設定
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
