//
//  CategoryInputViewController.swift
//  taskApp
//
//  Created by Tatsunori Watabe on 2017/05/04.
//  Copyright © 2017年 konsukeyama. All rights reserved.
//

import UIKit
import RealmSwift

class CategoryInputViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var categoryNameField: UITextField!
    @IBOutlet weak var categoryView: UITableView!
    
    // var category: Category!

    // Realmインスタンスを取得する
    let realm = try! Realm()

    // 以降内容をアップデートするとリスト内は自動的に更新される
    var categoryArray = try! Realm().objects(Category.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        categoryView.delegate = self
        categoryView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // カテゴリ追加画面から戻る際に呼ばれる
    override func viewWillDisappear(_ animated: Bool) {
        print("カテゴリ入力から戻るよ")
    }

    //--- UITableViewDataSource のメソッド
    // データの数（=セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryArray.count // DBテーブルのレコード数
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なセルを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // セルに値を反映する
        let category = categoryArray[indexPath.row]
        cell.textLabel?.text = category.name // カテゴリ名

        return cell
    }
    
    //--- UITableViewDelegate のメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルをタップで編集画面へ遷移
        // performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            // 削除されたカテゴリを取得する
            let category = self.categoryArray[indexPath.row]
            
            // DBからカテゴリを削除する（アニメーション付き）
            try! realm.write {
                self.realm.delete(self.categoryArray[indexPath.row])
                categoryView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
        }
    }

    // カテゴリを追加する
    @IBAction func insertCategory(_ sender: Any) {
        if categoryNameField != nil {
            let category = Category() // クラスオブジェクトの初期化
            if categoryArray.count != 0 {
                // DBが0件でない場合、既存レコード数+1を新規idとして払い出す
                category.id = categoryArray.max(ofProperty: "id")! + 1
            }
            // DBをアップデートする
            try! realm.write {
                category.name = self.categoryNameField.text! // カテゴリ
                self.realm.add(category, update: true) // 更新する
            }
            // カテゴリ一覧を更新する
            self.categoryView.reloadData()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}
