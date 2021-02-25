//
//  TimeLineCommentViewController.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2021/02/14.
//  Copyright © 2021 佐々木　謙. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import Kingfisher

// ▼参照しているclass
// CommentStruct
// NewsCount
// UserDefault
// UserInfoStruct
// FirestoreCollectionName
// DateItems
// CommentInputAccessoryView

// コメントページを扱うクラス
class TimeLineCommentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CommentInputAccessoryViewProtocol {
    
    
    // MARK: - Property
    // TableViewのインスタンス
    @IBOutlet weak var commentTable: UITableView!
    
    // コメント送信用viewのインスタンス
    lazy var commentInputAccessoryView: CommentInputAccessoryView = {
        
        let view = CommentInputAccessoryView()
        view.frame = .init(x: 0, y: 0, width: view.frame.width, height: 100)
        
        // プロトコルを委託
        view.commentInputAccessoryViewProtocol = self
        
        return view
    }()
    
    // 構造体のインスタンス
    var commentStruct : [CommentStruct]   = []
    var userInfomation: [UserInfoStruct]  = []
    var blockUsers    : [BlockUsers]      = []
    
    
    // MARK: - FireStore Property
    // fireStoreのインスタンス
    let fireStoreDB = Firestore.firestore()
    
    // 選択した投稿内容のdocumentIDを受け取る
    var idString: String?
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ダークモード適用を回避
        self.overrideUserInterfaceStyle = .light
        
        // delegateを委託
        commentTable.delegate   = self
        commentTable.dataSource = self
        
        // カスタムセルの登録
        commentTable.register(UINib(nibName: "TimeLineTableViewCell", bundle: nil), forCellReuseIdentifier: "timeLineCustomCell")
        
        // カスタムセルの高さの初期値を設定し、セルごとに可変するセルを作成
        commentTable.estimatedRowHeight = 95
        commentTable.rowHeight = UITableView.automaticDimension
    }
    
    
    // MARK: - ViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // fireStoreDBからユーザー情報を取得する
        loadUserInfomation()
        
        // コメント投稿内容を取得する
        loadComment()
    }
    
    
    // MARK: - LoadUserInfo
    // fireStoreDBからユーザー情報を取得する
    func loadUserInfomation() {
        
        self.fireStoreDB.collection(FirestoreCollectionName.users).document(Auth.auth().currentUser!.uid).getDocument {
            (document, error) in
            
            // エラー処理
            if error != nil {
                
                print("UserInfo acquisition error: \(error.debugDescription)")
                return
            }
            
            // document == fireStoreDBからdocumentIDを指定して取得
            if let document = document {
                let dataDescription = document.data()
                
                // アカウント情報を受け取る準備
                self.userInfomation = []
                
                // キー値を指定して値を取得
                let documentUserName  = dataDescription!["userName"] as? String
                let documentUserImage = dataDescription!["userImage"] as? String
                let documentSender    = dataDescription!["sender"] as? String
                
                // 構造体にまとめてユーザー情報を保管
                let userInfo = UserInfoStruct(userName: documentUserName!, userImage: documentUserImage!, sender: documentSender!)
                
                // UserInfoStruct型で保存してUIを更新
                self.userInfomation.append(userInfo)
                self.commentTable.reloadData()
            }
        }
    }
    
    
    // MARK: - LoadComment
    // fireStoreDBから値を取得してUIを更新
    func loadComment() {
        
        // 投稿日時の早い順に値をsnapShotに保存
        fireStoreDB.collection(FirestoreCollectionName.timeLineMessages).document(idString!).collection(FirestoreCollectionName.comments).order(by: "createdTime", descending: true).addSnapshotListener {
            (snapShot, error) in
            
            // 投稿情報を受け取る準備
            self.commentStruct = []
            
            // ブロックしたユーザーが存在しない場合（ブロック履歴がない場合）
            if UserDefault.standard.object(forKey: "blocked") == nil {
                
                let blocked = ["エラー回避値" : true]
                
                // エラー回避のためにキー値に初期値を保存
                UserDefault.standard.set(blocked, forKey: "blocked")
            }
            
            // 事前にブロックユーザーの情報を取得する
            let blockList: [String:Bool] = UserDefault.standard.object(forKey: "blocked") as! [String : Bool]
            
            // エラー処理
            if error != nil {
                
                print("Message acquisition error: \(error.debugDescription)")
                return
            }
            
            // snapShotの中に保存されている値を取得する
            if let snapShotDocuments = snapShot?.documents {
                
                for document in snapShotDocuments {
                    
                    // fireStoreDBのドキュメントのコレクションのインスタンス
                    let documentData = document.data()
                    
                    // 'ユーザー名', 'コメント'などをインスタンス化して新規コメントとしてnewCommentに保存
                    let documentUserName   = documentData["userName"] as? String
                    let documentAiconImage = documentData["aiconImage"] as? String
                    let documentComment    = documentData["comment"] as? String
                    let documentSender     = documentData["sender"] as? String
                    
                    // timestampを取得してDate型に変換
                    let timestamp: Timestamp = documentData["createdTime"] as! Timestamp
                    let dateValue = timestamp.dateValue()
                    
                    // 地域とスタイルを指定してString型へ変換
                    DateItems.dateFormatter.locale = Locale(identifier: "ja_JP")
                    DateItems.dateFormatter.dateStyle = .short
                    DateItems.dateFormatter.timeStyle = .short
                    let createdTime = DateItems.dateFormatter.string(from: dateValue)
                    
                    // key[documentSender(sender)]が存在し、値がtrueならtimeLineMessagesに加えない
                    if let blockFlag = blockList[documentSender!], blockFlag == true {
                        // ここは何もしない
                    } else {
                        
                        // fireStoreDBから取得した情報を構造体を用いて保存
                        let newComment = CommentStruct(sender: documentSender!, comment: documentComment!, aiconImage: documentAiconImage!, userName: documentUserName!, createdTime: createdTime, documentID: document.documentID)
                        
                        // CommentStruct型の最新投稿内容（ブロックユーザーは含まない）
                        self.commentStruct.append(newComment)
                        
                        // チャット投稿内容の更新
                        self.commentTable.reloadData()
                    }
                }
            }
        }
    }


    // MARK: - InputAccessoryView
    // CommentViewControllerにcommentInputAccessoryViewを反映
    override var inputAccessoryView: UIView? {
        get {
            return commentInputAccessoryView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }

    
    // MARK: - TableView
    // セクションの数を設定
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // セルの数を決める
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentStruct.count
    }
    
    // セルの編集許可
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // セルの編集アクションをカスタム
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .default, title: "削除", handler: {
            (rowAction, indexPath) in
            
            // 削除するセルのDdokyumenntoID
            let deleteID = self.commentStruct[indexPath.row].documentID
            
            // 投稿内容をfireStoreDBから削除
            self.fireStoreDB.collection(FirestoreCollectionName.timeLineMessages).document(self.idString!).collection(FirestoreCollectionName.comments).document(deleteID).delete() {
                error in
                
                // エラー処理
                if let error = error {
                    print("Error removing document: \(error)")
                } else {
                    // コメントページを閉じる
                    self.dismiss(animated: true, completion: nil)
                }
            }
        })
        
        // 他ユーザーをブロックするアクションをカスタム
        let blockUserAction = UITableViewRowAction(style: .default, title: "ブロック", handler: {
            (rowAction, indexPath) in
            
            // アラートの作成
            let blockUserAlert = UIAlertController(title: "ブロックの確認",message: "\(self.commentStruct[indexPath.row].userName)さんを本当にブロックしますか？", preferredStyle: .alert)
            
            // アラートのボタン
            blockUserAlert.addAction(UIAlertAction(title: "いいえ", style: .cancel))
            blockUserAlert.addAction(UIAlertAction(title: "はい", style: .destructive, handler: {
                action in
                
                // ブロックしたユーザーが存在しない場合（ブロック履歴がない場合）
                if UserDefault.standard.object(forKey: "blocked") == nil {
                    
                    let blocked = ["エラー回避値" : true]
                    
                    // エラー回避のためにキー値に初期値を保存
                    UserDefault.standard.set(blocked, forKey: "blocked")
                }
                
                // この時点でキー値blockedに保存されている値をblockDictionaryに代入する
                var blockDictionary: [String:Bool] = UserDefault.standard.object(forKey: "blocked") as! [String : Bool]

                // 辞書型blockDictionaryに、key[sender], value-trueで値を追加
                blockDictionary[self.commentStruct[indexPath.row].sender] = true
                
                // キー値blockedに辞書型blockDictionaryを保存
                UserDefault.standard.set(blockDictionary, forKey: "blocked")
                
                // コメントページを閉じる
                self.dismiss(animated: true, completion: nil)
            }))
            // アラートの表示
            self.present(blockUserAlert, animated: true, completion: nil)
        })
        
        // カスタムアクションの背景色
        deleteAction.backgroundColor    = UIColor.red
        blockUserAction.backgroundColor = UIColor.blue
        
        // 投稿内容がカレントユーザーの場合はブロックをfalse、そうでない場合は削除をfalse
        if self.commentStruct[indexPath.row].sender == Auth.auth().currentUser?.uid {
            return [deleteAction]
        } else {
            return [blockUserAction]
        }
        
        return [deleteAction, blockUserAction]
    }
    
    // セルを構築する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // カスタムセルのIDでTimeLineTableViewCellのインスタンスを生成
        let cell = commentTable.dequeueReusableCell(withIdentifier: "timeLineCustomCell", for: indexPath) as! TimeLineTableViewCell
        
        // firestoreDBから取得した新規コメントを取得
        let commentMessage = commentStruct[indexPath.row]
        
        // セルに表示する内容を設定
        cell.senderName.text = commentMessage.userName
        cell.sendBody.text   = commentMessage.comment
        cell.sendImageView.kf.setImage(with: URL(string: commentMessage.aiconImage))
        cell.sendTime.text   = commentMessage.createdTime
        
        // 「コメントを見る」ラベルを削除
        cell.commentLabel.isHidden = true
        
        // セルとTableViewの背景色の設定
        cell.backgroundColor         = UIColor(hex: "f4f8fa")
        commentTable.backgroundColor = UIColor(hex: "f4f8fa")
        
        // 空のセルを削除
        commentTable.tableFooterView = UIView(frame: .zero)
        
        // セルのタップを無効
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        return cell
    }
    
    
    // MARK: - TapCloseCommentButton
    // ×ボタンをタップすると呼ばれる
    @IBAction func tapCloseCommentButton(_ sender: Any) {
        
        // コメントページを閉じる
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - TapedSendCommentButton
    // CommentInputAccessoryViewクラスから値を受け取る（送信内容）
    func tapedSendCommentButton(comment: String, sendTime: Date) {
        
        // 受け取った値をインスタンス化
        let commentBody = comment
        let createdTime = sendTime
        
        // 受け取った値がnilでなければ
        if commentBody != nil && createdTime != nil {
            
            // uidを取得してインスタンス化
            let sender = Auth.auth().currentUser?.uid
            
            // 1. ユーザー名
            // 2. アイコン画像
            // 3. コメント内容
            // 4. 投稿日時
            // 5. 送信者のuid
            // 計5点をfireStoreDBへ保存
            fireStoreDB.collection(FirestoreCollectionName.timeLineMessages).document(idString!).collection(FirestoreCollectionName.comments).document().setData(
                ["userName"   : userInfomation[NewsCount.zeroCount].userName,
                 "aiconImage" : userInfomation[NewsCount.zeroCount].userImage,
                 "comment"    : comment,
                 "createdTime": createdTime,
                 "sender"     : sender])
            
            // fireStoreDBに保存をしたら入力内容を空にしてキーボードを閉じる
            commentInputAccessoryView.commentTextView.text = ""
            commentInputAccessoryView.commentTextView.resignFirstResponder()
        }
    }
}
