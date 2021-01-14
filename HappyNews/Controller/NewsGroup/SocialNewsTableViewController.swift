//
//  TopNewsTableViewController.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2020/08/13.
//  Copyright © 2020 佐々木　謙. All rights reserved.
//

import UIKit
import SegementSlide
import ToneAnalyzer
import LanguageTranslator
import SwiftyJSON
import PKHUD
import Kingfisher

class SocialNewsTableViewController: UITableViewController,SegementSlideContentScrollViewDelegate, XMLParserDelegate, DoneCatchTranslationProtocol, DoneCatchAnalyzerProtocol {
    
    //XMLParserのインスタンスを作成
    var parser = XMLParser()
    
    //NewsItemsモデルのインスタンス作成
    var newsItems = [NewsItemsModel]()
    
    //RSSのパース内の現在の要素名を取得する変数
    var currentElementName: String?
    
    //XMLファイルを保存するプロパティ
    var xmlString: String?
    
    //RSSのnewsを補完する配列
    var newsTextArray: [Any] = []
    
    //LanguageTranslatorの認証キー
    var languageTranslatorApiKey  = "J4LQkEl7BWhZL2QaeLzRIRSwlg4sna1J7-09opB-9Gqf"
    var languageTranslatorVersion = "2018-05-01"
    var languageTranslatorURL     = "https://api.jp-tok.language-translator.watson.cloud.ibm.com"
    
    //ToneAnalyzerの認証キー
    var toneAnalyzerApiKey  = "9HLMaO_Rg7t9PC7D91M0otaiGfU31y09-DxiumDnZ2SR"
    var toneAnalyzerVersion = "2017-09-21"
    var toneAnalyzerURL     = "https://api.jp-tok.tone-analyzer.watson.cloud.ibm.com"
    
    //LanguageTranslationModelから渡ってくる値
    var translationArray      = [String]()
    var translationArrayCount = Int()
    
    //ToneAnalyzerModelから渡ってくる値
    var joyCountArray = [Int]()
    
    //joyの要素と認定されたニュースの配列と検索する際のカウント
    var joySelectionArray = [NewsItemsModel]()
    var newsCount         = 50
    
    //RSSから取得するURLのパラメータを排除したURLを保存する値
    var imageParameter: String?
    
    //前回起動時刻の保管場所
    var lastActivation: String?

    //UserDefaults.standardのインスタン作成
    var userDefaults = UserDefaults.standard
    
    //NewsViewControllerから渡ってくる値を保管する変数
    var indexNum: Int?
    
    //NewsViewControllerと通信をおこなう初期値
//    init(indexNumber: Int) {
//        
//        super.init(nibName: nil, bundle: nil)
//        indexNum = indexNumber
//    }
//    
//    //イニシャライザエラー処理
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //前回起動時刻の確認
        print("前回起動時刻: \(userDefaults.string(forKey: "lastActivation"))")
        
        //ダークモード適用を回避
        self.overrideUserInterfaceStyle = .light
      
        //XMLパースの呼び出し
        settingXML()
    
        //時間割の呼び出し
        timeComparison()
    }
    
    // MARK: - XML Parser
    //XMLファイルを特定してパースを開始する
    func settingXML(){
        
        //'社会'カテゴリのニュース（ニッポン放送）
        xmlString = "https://news.yahoo.co.jp/rss/media/nshaberu/all.xml"
        
        //XMLファイルをURL型のurlに変換
        let url:URL = URL(string: xmlString!)!
        
        //parserにurlを代入
        parser = XMLParser(contentsOf: url)!
        
        //XMLParserを委任
        parser.delegate = self
        
        //parseの開始
        parser.parse()
    }
    
    //XML解析を開始する場合(parser.parse())に呼ばれるメソッド
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentElementName = nil
        
        if elementName == "item" {
            newsItems.append(NewsItemsModel())
        } else {
            currentElementName = elementName
        }
    }
    
    //"item"の中身を判定するメソッド(要素の解析開始と値取得）
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        if newsItems.count > 0 {
            
            //配列の番号を合わせる
            //'link'と'image'はstringに分割で値が入るので初めて代入する値以外は取得しない
            let lastItem = newsItems[newsItems.count - 1]
            switch currentElementName {
            case "title":
                lastItem.title       = string
            case "link":
                if lastItem.url == nil {
                    lastItem.url     = string
                } else {
                    break
                }
            case "pubDate":
                lastItem.pubDate     = string
            case "description":
                lastItem.description = string
            case "image":
                //パラメータを排除して取得する
                if lastItem.image == nil {
                    imageParameter = string
                    let imageURL = imageParameter!.components(separatedBy: "?")
                    lastItem.image = imageURL[0]
                } else {
                    break
                }
            default:
                break
            }
        }
    }
    
    //RSS内のXMLファイルの各値の</item>に呼ばれるメソッド（要素の解析終了）
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        //新しい箱を準備
        self.currentElementName = nil
    }
    
    //XML解析でエラーが発生した場合に呼ばれるメソッド
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("error:" + parseError.localizedDescription)
    }
    
    // MARK: - LanguageTranslator
    func startTranslation() {
        
        //感情分析中であることをユーザーに伝える
        HUD.show(.labeledProgress(title: "Happyを分析中...", subtitle: nil))
        
        //XMLのニュースの順番と整合性を合わせるためreversedを使用。$iは合わせた番号の可視化（50 = first, 1 = last）
        for i in (1...50).reversed() {
            newsTextArray.append(newsItems[newsItems.count - i].title!.description + "$\(i)")
        }
        
        print("newsTextArray: \(newsTextArray.debugDescription)")
        
        //LanguageTranslatorModelへ通信
        let languageTranslatorModel = LanguageTranslatorModel(languageTranslatorApiKey: languageTranslatorApiKey, languageTranslatorVersion: languageTranslatorVersion,  languageTranslatorURL: languageTranslatorURL, newsTextArray: newsTextArray)
        
        //LanguageTranslatorModelの委託とJSON解析をセット
        languageTranslatorModel.doneCatchTranslationProtocol = self
        languageTranslatorModel.setLanguageTranslator()
    }
    
    //LanguageTranslatorModelから返ってきた値の受け取り
    func catchTranslation(arrayTranslationData: Array<String>, resultCount: Int) {
        
        translationArray      = arrayTranslationData
        translationArrayCount = resultCount
        
        print("translationArray: \(translationArray.debugDescription)")
        
        //配列内の要素を確認するとToneAnalyzerを呼び出す
        if translationArray != nil {
            
            //ToneAnalyzerの呼び出し
            startToneAnalyzer()
        } else {
            print("Failed because the value is nil.")
        }
    }
    
    // MARK: - ToneAnalyzer
    func startToneAnalyzer() {
        //translationArrayとAPIToneAnalyzerの認証コードで通信
        let toneAnalyzerModel = ToneAnalyzerModel(toneAnalyzerApiKey: toneAnalyzerApiKey, toneAnalyzerVersion: toneAnalyzerVersion, toneAnalyzerURL: toneAnalyzerURL, translationArray: translationArray)
        
        //ToneAnalyzerModelの委託とJSON解析をセット
        toneAnalyzerModel.doneCatchAnalyzerProtocol = self
        toneAnalyzerModel.setToneAnalyzer()
    }
    
    //ToneAnalyzerModelから返ってきた値の受け取り
    func catchAnalyzer(arrayAnalyzerData: Array<Int>) {
        
        //感情分析結果の確認
        print("arrayAnalyzerData.count: \(arrayAnalyzerData.count)")
        print("arrayAnalyzerData: \(arrayAnalyzerData.debugDescription)")
        
        //感情分析結果の保存
        userDefaults.set(arrayAnalyzerData, forKey: "joyCountArray")
        
        //UIの更新を行うメソッドの呼び出し
        reloadNewsData()
    }

    //感情分析結果を用いて新たにNewsの配列を作成し、UIの更新を行う
    func reloadNewsData() {
        
        //感情分析結果の取り出し
        joyCountArray = userDefaults.array(forKey: "joyCountArray") as! [Int]
        print("joyCountArray: \(joyCountArray)")
        
        //joyCountArrayの中身を検索し、一致 = 意図するニュースを代入
        for i in 0...joyCountArray.count - 1 {
            
            //'i'固定、その間に'y'を加算
            for y in 0...newsCount - 1 {
                
                switch self.joyCountArray != nil {
                case self.joyCountArray[i] == y:
                    self.joySelectionArray.append(self.newsItems[y])
                default:
                    break
                }
            }
            print("joySelectionArray\([i]): \(self.joySelectionArray[i].title.debugDescription)")
        }
   
        //感情分析結果と新たに作成した配列の比較
        if joySelectionArray.count == joyCountArray.count {
            
            //メインスレッドでUIの更新
            DispatchQueue.main.async {
                //tableViewの更新
                self.tableView.reloadData()
                
                //感情分析が終了したことをユーザーに伝える
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    HUD.show(.label("分析が終了しました"))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        HUD.hide(animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - TimeComparison
    //時間の比較とそれに合った処理をおこなう
    func timeComparison() {
        
        //現在時刻の取得
        let date = Date()
        let dateFormatter = DateFormatter()
        
        //日時のフォーマットと地域を指定
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone   = TimeZone(identifier: "Asia/Tokyo")
        
        //アプリ起動時刻を定義
        let currentTime = dateFormatter.string(from: date)
        print("現在時刻: \(currentTime)")
        
        //アプリ起動時刻の保存
        userDefaults.set(currentTime, forKey: "lastActivation")
        
        //定時時刻の設定
        let morningPoint     = dateFormatter.date(from: "07:00:00")
        let afternoonPoint   = dateFormatter.date(from: "11:00:00")
        let eveningPoint     = dateFormatter.date(from: "17:00:00")
        let nightPoint       = dateFormatter.date(from: "23:59:59")
        let lateAtNightPoint = dateFormatter.date(from: "00:00:00")
        
        //定時時刻の変換
        let morningTime     = dateFormatter.string(from: morningPoint!)
        let afternoonTime   = dateFormatter.string(from: afternoonPoint!)
        let eveningTime     = dateFormatter.string(from: eveningPoint!)
        let nightTime       = dateFormatter.string(from: nightPoint!)
        let lateAtNightTime = dateFormatter.string(from: lateAtNightPoint!)
        
        //前回起動時刻の取り出し
        lastActivation = userDefaults.string(forKey: "lastActivation")
        print("起動時刻更新: \(lastActivation)")
        
        //前回起動時刻と定時時刻の間隔で時間割（日付を無くして全て時間指定）
        //07:00以降11:00以前の場合
        if lastActivation!.compare(morningTime) == .orderedDescending && lastActivation!.compare(afternoonTime) == .orderedAscending {
            
            //UserDefaultsに'朝の更新完了'の値が無ければAPIと通信、あればキャッシュでUI更新
            if userDefaults.string(forKey: "SocialNews Morning Update") == nil {
                print("朝のAPI通信")
                //朝のAPI更新
                startTranslation()
                
                //UserDefaultsで値を保存して次回起動時キャッシュ表示に備える
                userDefaults.set("【朝】社会のニュース更新完了", forKey: "SocialNews Morning Update")
                
                //次回時間割に備えてUserDefaultsに保存した値を削除
                userDefaults.removeObject(forKey: "SocialNews lateAtNight Update")
                userDefaults.removeObject(forKey: "SocialNews Afternoon Update")
                userDefaults.removeObject(forKey: "SocialNews Evening Update")
            } else {
                
                //429エラーが多発して解析を中断した後に起動した際の処理
                if userDefaults.object(forKey: "Multiple 429 errors") != nil || userDefaults.object(forKey: "ToneAnalyzer: Unexpected errors occur.") != nil || userDefaults.object(forKey: "LanguageTranslator: Unexpected errors occur.") != nil {
                    
                    //改めて感情分析をおこなう
                    startTranslation()
                } else {
                    print("キャッシュの表示")
                    reloadNewsData()
                }
            }
        }
        
        //11:00以降17:00以前の場合
        else if lastActivation!.compare(afternoonTime) == .orderedDescending && lastActivation!.compare(eveningTime) == .orderedAscending {
            
            //UserDefaultsに'昼の更新完了'の値が無ければAPIと通信、あればキャッシュでUI更新
            if userDefaults.string(forKey: "SocialNews Afternoon Update") == nil {
                print("昼のAPI通信")
                //昼のAPI更新
                startTranslation()
                
                //UserDefaultsで値を保存して次回起動時キャッシュ表示に備える
                userDefaults.set("【昼】社会のニュース更新完了", forKey: "SocialNews Afternoon Update")

                //次回時間割に備えてUserDefaultsに保存した値を削除
                userDefaults.removeObject(forKey: "SocialNews Morning Update")
                userDefaults.removeObject(forKey: "SocialNews Evening Update")
                userDefaults.removeObject(forKey: "SocialNews lateAtNight Update")
            } else {
                print("キャッシュの表示")
                reloadNewsData()
            }
        }
        
        //17:00以降23:59:59以前の場合（1日の最後）
        else if lastActivation!.compare(eveningTime) == .orderedDescending && lastActivation!.compare(nightTime) == .orderedAscending {
            
            //UserDefaultsに'夕方のAPI更新完了（日付変更以前）'の値が無ければAPIと通信、あればキャッシュでUI更新
            if userDefaults.string(forKey: "SocialNews Evening Update") == nil {
                print("夕方のAPI通信（日付変更以前）")
                //夕方のAPI更新（日付変更以前）
                startTranslation()
                
                //UserDefaultsで値を保存して次回起動時キャッシュ表示に備える
                userDefaults.set("【夕方】社会のニュース更新完了", forKey: "SocialNews Evening Update")
                
                //次回時間割に備えてUserDefaultsに保存した値を削除
                userDefaults.removeObject(forKey: "SocialNews Afternoon Update")
                userDefaults.removeObject(forKey: "SocialNews lateAtNight Update")
                userDefaults.removeObject(forKey: "SocialNews Morning Update")
            } else {
                print("キャッシュの表示")
                reloadNewsData()
            }
        }
        
        //00:00以降07:00以前の場合（日を跨いで初めて起動）
        else if lastActivation!.compare(lateAtNightTime) == .orderedDescending && lastActivation!.compare(morningTime) == .orderedAscending  {
            
            //UserDefaultsに'夕方のAPI更新完了（日付変更以降）'値が無ければAPIと通信、あればキャッシュでUI更新
            if userDefaults.string(forKey: "SocialNews lateAtNight Update") == nil {
                print("夕方のAPI通信（日付変更以降）")
                //夕方のAPI更新（日付変更以降）
                startTranslation()
                
                //UserDefaultsで値を保存して次回起動時キャッシュ表示に備える
                userDefaults.set("【深夜】社会のニュース更新完了", forKey: "SocialNews lateAtNight Update")
                
                //次回時間割に備えてUserDefaultsに保存した値を削除
                userDefaults.removeObject(forKey: "SocialNews Evening Update")
                userDefaults.removeObject(forKey: "SocialNews Morning Update")
                userDefaults.removeObject(forKey: "SocialNews Afternoon Update")
            } else {
                print("キャッシュの表示")
                reloadNewsData()
            }
        }
        
        //どの時間割にも当てはまらない場合
        else {
            print("キャッシュの表示")
            reloadNewsData()
        }
    }
    
    // MARK: - Table view data source
    //tableViewを返すメソッド
    @objc var scrollView: UIScrollView {
        return tableView
    }
    
    //セルのセクションを決めるメソッド
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //セルの数を決めるメソッド
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return joySelectionArray.count
    }
    
    //セルの高さを決めるメソッド
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.size.height/6
    }
    
    //セルを構築する際に呼ばれるメソッド
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //RSSで取得したニュースの値が入る
        let newsItem = joySelectionArray[indexPath.row]
        
        //セルのスタイルを設定
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell" )
        
        //サムネイルのインスタンス(画像URL, 待機画像, 角丸）
        let thumbnailURL = URL(string: joySelectionArray[indexPath.row].image!.description)
        let placeholder  = UIImage(named: "placeholder")
        let cornerRadius = RoundCornerImageProcessor(cornerRadius: 20)
        
        //サムネイルの反映
        cell.imageView?.kf.setImage(with: thumbnailURL, placeholder: placeholder, options: [.processor(cornerRadius), .transition(.fade(0.2))])
        
        //サムネイルのサイズを統一（黄金比）
        cell.imageView?.image = cell.imageView?.image?.resize(_size: CGSize(width: 135, height: 85))
        
        //セルを化粧
        cell.backgroundColor = UIColor.white
        cell.textLabel?.text = newsItem.title
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        cell.textLabel?.textColor = UIColor(hex: "333")
        cell.textLabel?.numberOfLines = 2
        
        //空のセルを削除
        tableView.tableFooterView = UIView(frame: .zero)
        
        //tableaviewの背景
        tableView.backgroundColor = UIColor.white
        
        //セルのサブタイトル
        cell.detailTextLabel?.text = joySelectionArray[indexPath.row].pubDate
        cell.detailTextLabel?.textColor = UIColor.gray
        
        return cell
    }
    
    //セルをタップした時呼ばれるメソッド
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //タップ時の選択色の常灯を消す
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        //WebViewControllerのインスタンス作成
        let webViewController = WebViewController()
        
        //WebViewのNavigationControllerを定義
        let webViewNavigation = UINavigationController(rootViewController: webViewController)
        
        //WebViewをフルスクリーンに
        webViewNavigation.modalPresentationStyle = .fullScreen
        
        //タップしたセルを検知
        let tapCell = joySelectionArray[indexPath.row]
        
        //検知したセルのurlを取得
        userDefaults.set(tapCell.url, forKey: "url")
        
        //webViewControllerへ遷移
        present(webViewNavigation, animated: true)
    }
}
