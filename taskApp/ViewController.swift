//
//  ViewController.swift
//  taskApp
//
//  Created by Tatsunori Watabe on 2017/04/30.
//  Copyright © 2017年 konsukeyama. All rights reserved.
//

import UIKit
import RealmSwift // Realm（DB）使用
import UserNotifications // 通知用ライブラリ

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchCategory: UISearchBar!

    // Realmインスタンスを取得する
    let realm = try! Realm()

    // DB内のタスクが格納されるリスト（日付の降順でソート）
    // 以降内容をアップデートするとリスト内は自動的に更新される
    var taskArray = try! Realm().objects(Task.self).sorted(byProperty: "date", ascending: false)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // テーブル初期設定
        tableView.delegate = self
        tableView.dataSource = self
        
        // 検索バー初期設定
        searchCategory.delegate = self // 検索バーをデリゲート
        searchCategory.showsCancelButton = true // キャンセルボタン：有効
        searchCategory.showsSearchResultsButton = false // 検索結果ボタン[▼]：有効
        searchCategory.enablesReturnKeyAutomatically = false // 入力値が空でも検索を有効にする
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //--- 検索バーまわりのメソッド
    // 検索ボタンが押下
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true) // キーボード閉じる
        if searchCategory.text != nil {
            if searchCategory.text == "" {
                // 検索内容が空の場合
                taskArray = try! Realm().objects(Task.self).sorted(byProperty: "date", ascending: false)
            } else {
                // 検索内容が空でない場合、DB内のカテゴリと該当するレコードを取得する
                taskArray = try! Realm().objects(Task.self).filter("category = %@", searchCategory.text!).sorted(byProperty: "date", ascending: false)
            }
        }
        self.tableView.reloadData() // テーブル内容を更新
    }
    // キャンセルボタン押下
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true) // キーボード閉じる
    }

    //--- 画面遷移まわりのメソッド
    // segueで画面遷移する際に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        // segue判定
        if segue.identifier == "cellSegue" {
            // 既存タスクのデータ
            let indexPath = self.tableView.indexPathForSelectedRow // 選択状態のセル
            inputViewController.task = taskArray[indexPath!.row] // ここで渡す
        } else {
            // 新規タスクのデータ
            let task = Task()
            task.date = NSDate() // 現在日時の取得
            
            if taskArray.count != 0 {
                // DBが0件でない場合、DBのレコード数+1を新規idとして払い出す
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task // ここで渡す
        }
    }
    
    // 入力画面から戻ってきた際に呼ばれる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // テーブルビューを更新する
        tableView.reloadData()
    }

    //--- UITableViewDataSource のメソッド
    // データの数（=セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count // DBテーブルのレコード数
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能なセルを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // セルに値を反映する
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title // タイトル
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dataString: String = formatter.string(from: task.date as Date) // 日付をフォーマット
        cell.detailTextLabel?.text = dataString // 日付
        
        return cell
    }
    
    //--- UITableViewDelegate のメソッド
    // 各セルを選択した時に実行さえるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルをタップで編集画面へ遷移
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ taleView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current() // 通知を登録
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)]) // 削除したタスクidの通知を削除

            // DBからタスクを削除する（アニメーション削除）
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 未通知のローカル通知一覧をログ出力（デバッグ用）
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
}

