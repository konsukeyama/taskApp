//
//  InputViewController.swift
//  taskApp
//
//  Created by Tatsunori Watabe on 2017/05/02.
//  Copyright © 2017年 konsukeyama. All rights reserved.
//

import UIKit
import RealmSwift // DB（Realm）使用
import UserNotifications // 通知用ライブラリ

// ピッカー利用のため UIPickerViewDelegate, UIPickerViewDataSource 追加
class InputViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var categoryPicker: UIPickerView! // カテゴリ
    let sampleValues: NSArray = ["aaa", "bbb", "ccc", "ddd"]
    // @IBOutlet weak var categoryTextField: UITextField! // カテゴリ
    @IBOutlet weak var titleTextField: UITextField!    // タイトル
    @IBOutlet weak var contentsTextView: UITextView!   // 内容
    @IBOutlet weak var datePicker: UIDatePicker!       // 日付

    // Realmインスタンスを取得する
    let realm = try! Realm()

    // 一覧画面から渡された値を受け取るプロパティ
    var task: Task!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        // ピッカーをデリゲート
        categoryPicker.delegate = self
        categoryPicker.dataSource = self

        
        //--- メインアクション
        // 背景タップで dismissKeyboard() を呼ぶ
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard)) // tapGestureの初期化
        self.view.addGestureRecognizer(tapGesture) // [self.view]が背景という意味
        
        // 入力項目の初期値セット
        // categoryTextField.text = task.category // カテゴリ
        titleTextField.text = task.title       // タイトル
        contentsTextView.text = task.contents  // 内容
        datePicker.date = task.date as Date    // 日付
        
        // テキストフィールドの装飾
        contentsTextView.layer.borderColor = RGBA(red: 200, green: 200, blue: 200, alpha: 1).cgColor
        contentsTextView.layer.borderWidth = 1
        contentsTextView.layer.cornerRadius = 10
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 画面が閉じられる際に呼ばれるメソッド
    /*
    override func viewWillDisappear(_ animated: Bool) {
        // DBをアップデートする
        try! realm.write {
            self.task.category = self.categoryTextField.text! // カテゴリ
            self.task.title = self.titleTextField.text!       // タイトル
            self.task.contents = self.contentsTextView.text   // 内容
            self.task.date = self.datePicker.date as NSDate   // 日付
            self.realm.add(self.task, update: true) // 更新する
        }
        
        // ローカル通知を登録
        setNotification(task: task)
        
        // 画面を閉じる
        super.viewWillDisappear(animated)
    }
    */
    
    //--- ピッカー用メソッド
    // 表示する列数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    // ピッカーに表示する行数を返す
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sampleValues.count
    }
    
    // ピッカーに表示する値を返す
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sampleValues[row] as? String
    }
    
    // ピッカーが選択された際に呼ばれる
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        print("row: \(row)")
        print("value: \(sampleValues[row])")
    }
    
    // キーボードを閉じる
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // UIColorをRGBA指定する
    func RGBA(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        let r = red / 255.0
        let g = green / 255.0
        let b = blue / 255.0
        let rgba = UIColor(red: r, green: g, blue: b, alpha: alpha)
        return rgba
    }
    
    // タスクのローカル通知を登録する（1〜4の流れで登録　※理解に苦しんだ...）
    func setNotification(task: Task) {
        // 1.通知内容を設定
        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.contents // bodyが空の場合は音のみの通知になる
        content.sound = UNNotificationSound.default()
        
        // 2.通知を発動させるトリガーを作成（タスクの日時で発動させる）
        let calendar = NSCalendar.current // （世界標準時で）カレンダーを作成
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date as Date) // dateComponentsを作成（今回は年、月、日、時、分をタスクの日時から作成）
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponents, repeats: false) // トリガーを作成する（発動する日付（※DateComponentsで指定する。指定は必要最小限でOK）、繰り返しなし）

        // 3.identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest.init(identifier: String(task.id), content: content, trigger: trigger)
        
        // 4.ローカル通知を登録
        let center = UNUserNotificationCenter.current() // 通知を登録
        center.add(request) { (error) in // 通知を実行し、エラーならコンソールにエラーを出力する
            if let errMsg = error { // エラーがあれば出力する
                print(errMsg)
            }
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
    
    @IBAction func insertTask(_ sender: Any) {
        // DBをアップデートする
        try! realm.write {
            // self.task.category = self.categoryTextField.text! // カテゴリ
            self.task.title = self.titleTextField.text!       // タイトル
            self.task.contents = self.contentsTextView.text   // 内容
            self.task.date = self.datePicker.date as NSDate   // 日付
            self.realm.add(self.task, update: true) // 更新する
        }
        
        // ローカル通知を登録
        setNotification(task: task)
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
