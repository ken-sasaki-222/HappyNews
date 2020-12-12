//
//  ViewController.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2020/08/13.
//  Copyright © 2020 佐々木　謙. All rights reserved.
//

import UIKit
import SegementSlide

//16進数color 機能拡張
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let v = Int("000000" + hex, radix: 16) ?? 0
        let r = CGFloat(v / Int(powf(256, 2)) % 256) / 255
        let g = CGFloat(v / Int(powf(256, 1)) % 256) / 255
        let b = CGFloat(v / Int(powf(256, 0)) % 256) / 255
        self.init(red: r, green: g, blue: b, alpha: min(max(alpha, 0), 1))
    }
}

class NewsViewController: SegementSlideDefaultViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NavigationBarの呼び出し
        setNewsNavigationBar()
        
        //SegementSlideDefaultViewControllerの初期設定
        defaultSelectedIndex = 0
        reloadData()
    }
    
    //ニュースページのNavigationBar設定
    func setNewsNavigationBar() {
        
        //NavigationBarのtitleとその色とフォント
        navigationItem.title = "HapyNews"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 19.0, weight: .medium)]
        
        //NavigationBarの色
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "00AECC")
        
        //一部NavigationBarがすりガラス？のような感じになるのでfalseで統一
        self.navigationController?.navigationBar.isTranslucent = false
        
        //NavigationBarの下線を消す
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
    }
    
    //ニュースタブのコード
    override var titlesInSwitcher: [String] {
        
        return ["社会","スポーツ","エンタメ","ビジネス・経済","IT・化学"]
    }

    //コントローラーを返すメソッド
    override func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {

        switch index {
        case 0:
            return TopNewsTableViewController()
        case 1:
            return nil//SuportsNewsTableViewController()
        case 2:
            return nil//EntameNewsTableViewController()
        case 3:
            return nil//BusinessNewsTableViewController()
        case 4:
            return nil//TechnologyNewsTableViewController()
        default:
            return TopNewsTableViewController()
        }
    }
}

