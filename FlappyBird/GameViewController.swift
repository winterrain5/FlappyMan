//
//  GameViewController.swift
//  FlappyBird
//
//  Created by pmst on 15/10/4.
//  Copyright (c) 2015年 pmst. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let skView = self.view as? SKView {
            if skView.scene == nil {
                // 创建场景
                // 获取宽高比例
                let ratio = skView.bounds.size.height / skView.bounds.size.width
                let scene = GameScene(size: CGSize(width: 320, height: 320*ratio), gameState: .MainMenu)
                
                skView.showsFPS = true
                skView.showsNodeCount = true //显示当前场景下节点个数
                skView.showsPhysics = false // 显示物理体
                skView.ignoresSiblingOrder = true // 忽略节点添加顺序
                
                scene.scaleMode = .aspectFill
                
                // 呈现场景
                skView.presentScene(scene)
                
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
   
}
