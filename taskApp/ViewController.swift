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

// ピッカー利用のため UIPickerViewDelegate, UIPickerViewDataSource 継承
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectCategory: UITextField!

    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // ピッカー作成
    var pickerView: UIPickerView = UIPickerView()

    // DBからデータを取得
    var taskArray = try! Realm().objects(Task.self).sorted(byProperty: "date", ascending: false) // タスク
    let categoryArray = try! Realm().objects(Category.self)                                      // カテゴリ

    // その他
    var pickerSelectRow = 0 // 選択したピッカー行の保持用（doneで使用）

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // テーブル初期設定
        tableView.delegate = self
        tableView.dataSource = self

        // ピッカー初期設定
        pickerView.delegate = self
        pickerView.dataSource = self

        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 35)) // ツールバーの表示位置（inputAccessoryViewだと高さ以外効かない？）
        let doneItem = UIBarButtonItem(title: "決定", style: .plain, target: self, action: #selector(self.done))          // 確定ボタン
        let cancelItem = UIBarButtonItem(title: "キャンセル", style: .plain, target: self, action: #selector(self.cancel)) // キャンセルボタン
        toolbar.setItems([doneItem, cancelItem], animated: true) // ツールバーにボタンを配置
        
        self.selectCategory.inputView = pickerView       // ソフトウェアキーボードをピッカーに変更
        self.selectCategory.inputAccessoryView = toolbar // ツールバーを挿入
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //--- ピッカー用メソッド
    // 表示する列数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // ピッカーに表示する行数を返す
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }

    // ピッカーに表示する値を返す
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row]["name"] as? String
    }
    
    // ピッカーが選択された際に呼ばれる
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickerSelectRow = row // 選択された行を保持
    }

    // キャンセルボタン押下
    func cancel() {
        self.selectCategory.endEditing(true)
    }
    
    // 確定ボタン押下
    func done() {
        self.selectCategory.endEditing(true)
        self.selectCategory.text = categoryArray[pickerSelectRow]["name"] as? String
        searchTaskView() // タスクを取得
    }

    // DBから該当するタスクを取得＆表示する
    func searchTaskView() {
        if selectCategory.text != nil {
            if selectCategory.text == "" {
                // 検索内容が空の場合、DB内の全レコードを取得
                taskArray = try! Realm().objects(Task.self).sorted(byProperty: "date", ascending: false)
            } else {
                // 検索内容が空でない場合、DB内の該当するカテゴリのレコードを取得
                taskArray = try! Realm().objects(Task.self).filter("category = %@", selectCategory.text!).sorted(byProperty: "date", ascending: false)
            }
        }
        self.tableView.reloadData() // テーブル内容を更新
    }

    // キャンセルボタン押下時に呼ばれる
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true) // キーボード閉じる
    }

    //--- 画面遷移まわりのメソッド
    // segueで画面遷移する際に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let inputViewController: InputViewController = segue.destination as! InputViewController
        
        // segue判定
        if segue.identifier == "cellSegue" {
            // 既存タスクの編集
            let indexPath = self.tableView.indexPathForSelectedRow // 選択状態のセル
            inputViewController.task = taskArray[indexPath!.row] // ここで渡す
        } else {
            // 新規タスクの追加
            let task = Task() // クラスオブジェクトの初期化
            task.date = NSDate() // 現在日時の取得（遷移先でちゃんと日本時間になるのはナゼ...？）
            
            if taskArray.count != 0 {
                // DBが0件でない場合、既存レコード数+1を新規idとして払い出す（疑似オートインクリメント）
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task // ここで渡す
        }
    }
    
    // タスク追加画面から戻ってきた際に呼ばれる
    @IBAction func unwind(segue: UIStoryboardSegue) {
        // テーブルビューを更新する
        self.tableView.reloadData()
    }
    
    // タスク全件表示ボタン
    @IBAction func crrentTaskView(_ sender: Any) {
        self.selectCategory.text = ""
        searchTaskView() // タスクを取得
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
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルをタップで編集画面へ遷移
        performSegue(withIdentifier: "cellSegue", sender: nil)
    }
    
    // セルが削除可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // 削除されたタスクのローカル通知を削除する
            let center = UNUserNotificationCenter.current() // 通知を登録
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)]) // 削除したタスクidの通知を削除

            // DBからタスクを削除する（アニメーション付き）
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

