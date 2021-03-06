//
//  SceneDelegate.swift
//  HappyNews
//
//  Created by 佐々木　謙 on 2020/08/13.
//  Copyright © 2020 佐々木　謙. All rights reserved.
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // ログインしていればTabBarから起動、そうでなければログイン画面から
        if Auth.auth().currentUser != nil {
            
            let window = UIWindow(windowScene: scene as! UIWindowScene)
            self.window = window
            window.makeKeyAndVisible()
            
            // Storyboardをインスタンス化
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // TabBarControllerをインスタンス化
            let tabVC = storyboard.instantiateViewController(identifier: "tabVC") as! TabBarController
            
            // TabBarControllerから表示
            window.rootViewController = tabVC
        } else {
            
            let window = UIWindow(windowScene: scene as! UIWindowScene)
            self.window = window
            window.makeKeyAndVisible()
            
            // Storyboardをインスタンス化
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // LoginViewControllerをインスタンス化
            let loginVC = storyboard.instantiateViewController(identifier: "loginVC")

            // LoginViewControllerから表示
            window.rootViewController = loginVC
        }
        
        
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard (scene as? UIWindowScene) != nil else { return }
//            let window = UIWindow(windowScene: scene)
//            self.window = window
//
//            let vc = MainTabBarController()
//            window.rootViewController = vc
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

