//
//  GameScene.swift
//  FlappyBird
//
//  Created by pmst on 15/10/4.
//  Copyright (c) 2015年 pmst. All rights reserved.
//

import SpriteKit
enum Layer:CGFloat {
    case Background
    case Obstacle
    case Foreground
    case Player
    case UI
    case Flash
}
/*
 MaiMenu。开始一次游戏、查看排名以及游戏帮助。
 Tutorial。考虑到新手对于新游戏的上手，在选择进行一次新游戏时，展示玩法教程显然是一个明确且友好的措施。
 Play。正处于游戏的状态。
 Falling。Player因为不小心碰到障碍物失败下落时刻。注意:接触障碍物，失败掉落才算!
 ShowingScore。显示得分。
 GameeOver。告知游戏结束
 */
enum GameState {
    case MainMenu
    case Tutorial
    case Play
    case Falling
    case ShowingScore
    case GameOver
}
struct PhysicsCategory {
    static let None:UInt32 = 0
    static let Player:UInt32 = 0b1
    static let Obstacle:UInt32 = 0b10
    static let Ground:UInt32 = 0b100
}
class GameScene: SKScene ,SKPhysicsContactDelegate{
    
    // MARK: 常量
    let kGravity:CGFloat = -1500.0 //重力
    let kImpluse:CGFloat = 400 // 上升力
    let kGroundSpeed:CGFloat = 150.0
    let kFontName = "AmericanTypewriter-Bold"
    let kMargin:CGFloat = 20
    let kAnimDelay = 0.3
    
    let worldNode = SKNode()
    var playableStart:CGFloat = 0
    var playableHeight:CGFloat = 0
    
    let player = SKSpriteNode(imageNamed: "Bird0")
    var lastUpdateTime:TimeInterval = 0
    var dt:TimeInterval = 0
    var playerVelocity:CGPoint = .zero // 速度
    
    // MARK: 音乐Action
    let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    
    //新增三个常量
    let kBottomObstacleMinFraction: CGFloat = 0.1
    let kBottomObstacleMaxFraction: CGFloat = 0.6
    let kGapMultiplier: CGFloat = 5
    
    // 新增常量
    let kMinDegrees: CGFloat = -90            // 定义Player最小角度为-90
    let kMaxDegrees: CGFloat = 25            // 定义Player最大角度为25
    let kAngularVelocity: CGFloat = 1000.0    // 定义角速度

    // 新增变量
    var playerAngularVelocity: CGFloat = 0.0    // 实时更新player的角度
    var lastTouchTime: TimeInterval = 0        // 用户最后一次点击时间
    var lastTouchY: CGFloat = 0.0                // 用户最后一次点击坐标
    
    let sombrero = SKSpriteNode(imageNamed: "Sombrero")
    var hitGround = false
    var hitObstacle = false
    var gameState: GameState = .Play
    
    var scoreLabel:SKLabelNode!
    var score:Int = 0
    
    init(size:CGSize,gameState:GameState) {
        self.gameState = gameState
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        addChild(worldNode)
        
        if gameState == .MainMenu {
            switchToMainMenu()
        }else {
            switchToTutorial()
        }
       
    }
    
    func switchToMainMenu() {
        gameState = .MainMenu
        setupBackground()
        setupForeground()
        setupPlayer()
        setupSomebrero()
        //TODO: 实现setupMainMenu()主界面布局
        setupMainMenu()
    }
    
    func switchToTutorial() {
        gameState = .Tutorial
        setupBackground()
        setupForeground()
        setupPlayer()
        setupSomebrero()
        setupLabel()
        //TODO: 实现setupTutorial()教程界面布局
        setupTutorial()
    }
    
    func setupBackground() {
        let background = SKSpriteNode(imageNamed: "Background")
        background.anchorPoint = CGPoint(x: 0.5, y: 1)
        background.position = CGPoint(x: size.width/2, y: size.height)
        background.zPosition = Layer.Background.rawValue
        worldNode.addChild(background)
        
        playableStart = size.height - background.size.height
        playableHeight = background.size.height
        
        // 地板表面最左侧 最右侧
        let lowerLeft = CGPoint(x: 0, y: playableStart)
        let lowerRight = CGPoint(x: size.width, y: playableStart)
        
        physicsBody = SKPhysicsBody(edgeFrom: lowerLeft, to: lowerRight)
        physicsBody?.categoryBitMask = PhysicsCategory.Ground
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = PhysicsCategory.Player
    }
    
    // 首先SpriteKit中坐标系与之前不同，原点位于左下角，x轴正方向自左向右，y轴正方向自下向上；其次wordNode节点位于原点处，因此它内部的坐标系也是以左下角为原点
    func setupForeground() {
        for i in 0..<2 {
            let foreground = SKSpriteNode(imageNamed: "Ground")
            foreground.anchorPoint = CGPoint(x: 0, y: 1)
            foreground.position = CGPoint(x: CGFloat(i) * size.width, y: playableStart)
            foreground.zPosition = Layer.Foreground.rawValue
            foreground.name = "foreground"
            worldNode.addChild(foreground)
        }
        
    }
    
    /// 创建飞行精灵
    func setupPlayer() {
        player.position = CGPoint(x: size.width * 0.2, y: playableHeight * 0.6 + playableStart)
        player.zPosition = Layer.Player.rawValue
        
        let offsetX = player.size.width * player.anchorPoint.x
        let offsetY = player.size.height * player.anchorPoint.y
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 17 - offsetX, y: 23 - offsetY))
        path.addLine(to: CGPoint(x: 39 - offsetX, y: 22 - offsetY))
        path.addLine(to: CGPoint(x: 38 - offsetX, y: 10 - offsetY))
        path.addLine(to: CGPoint(x: 21 - offsetX, y: 0 - offsetY))
        path.addLine(to: CGPoint(x: 4 - offsetX, y: 1 - offsetY))
        path.addLine(to: CGPoint(x: 3 - offsetX, y: 15 - offsetY))
        path.closeSubpath()
        
        player.physicsBody = SKPhysicsBody(polygonFrom: path)
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Obstacle | PhysicsCategory.Ground
        
        worldNode.addChild(player)
    }
    
    func setupSomebrero(){
//        sombrero.position = CGPoint(x:31 - sombrero.size.width/2, y:29 - sombrero.size.height/2)
//        player.addChild(sombrero)
    }
    
    func setupLabel() {
        scoreLabel = SKLabelNode(fontNamed: kFontName)
        scoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1)
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - kMargin)
        scoreLabel.text = "0"
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = Layer.UI.rawValue
        worldNode.addChild(scoreLabel)
    }
    
    /// 得分面板
    func setupScoreCard() {
        if score > bestScore() {
            setBsetScore(score)
        }
        
        // 得分面板背景
        let scorecard = SKSpriteNode(imageNamed: "ScoreCard")
        scorecard.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        scorecard.name = "Tutorial"
        scorecard.zPosition = Layer.UI.rawValue
        worldNode.addChild(scorecard)
        
        // 本次得分
        let lastScore = SKLabelNode(fontNamed: kFontName)
        lastScore.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1)
        lastScore.position = CGPoint(x: -scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
        lastScore.text = "\(score)"
        scorecard.addChild(lastScore)
        
        // 最好成绩
        let bestScoreLabel = SKLabelNode(fontNamed: kFontName)
        bestScoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        bestScoreLabel.position = CGPoint(x: scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
        bestScoreLabel.text = "\(self.bestScore())"
        scorecard.addChild(bestScoreLabel)
        
        // 4 游戏结束
        let gameOver = SKSpriteNode(imageNamed: "GameOver")
        gameOver.position = CGPoint(x: size.width/2, y: size.height/2 + scorecard.size.height/2 + kMargin + gameOver.size.height/2)
        gameOver.zPosition = Layer.UI.rawValue
        worldNode.addChild(gameOver)
        
        // 5 ok按钮背景以及ok标签
        let okButton = SKSpriteNode(imageNamed: "Button")
        okButton.position = CGPoint(x: size.width * 0.25, y: size.height/2 - scorecard.size.height/2 - kMargin - okButton.size.height/2)
        okButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(okButton)
        
        
        let ok = SKSpriteNode(imageNamed: "OK")
        ok.position = .zero
        ok.zPosition = Layer.UI.rawValue
        okButton.addChild(ok)
        
        // 6 share按钮背景以及share标签
        let shareButton = SKSpriteNode(imageNamed: "Button")
        shareButton.position = CGPoint(x: size.width * 0.75, y: size.height/2 - scorecard.size.height/2 - kMargin - shareButton.size.height/2)
        shareButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(shareButton)
        
        
        let share = SKSpriteNode(imageNamed: "Share")
        share.position = .zero
        share.zPosition = Layer.UI.rawValue
        shareButton.addChild(share)
        
        gameOver.setScale(0)
        gameOver.alpha = 0
        let group = SKAction.group([
            SKAction.fadeIn(withDuration: kAnimDelay),
            SKAction.scale(to: 1, duration: kAnimDelay)
        ])
        group.timingMode = .easeInEaseOut
        gameOver.run(SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay),
            group
        ]))
        
        scorecard.position = CGPoint(x: size.width * 0.5, y: -scorecard.size.height/2)
        let moveTo = SKAction.move(to: CGPoint(x: size.width/2, y: size.height/2), duration: kAnimDelay)
        moveTo.timingMode = .easeInEaseOut
        scorecard.run(SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay * 2),
            moveTo
        ]))
        
        okButton.alpha = 0
        shareButton.alpha = 0
        let fadeIn = SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay * 3),
            SKAction.fadeIn(withDuration: kAnimDelay)
        ])
        okButton.run(fadeIn)
        shareButton.run(fadeIn)
        
        let pops = SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay),
            popAction,
            SKAction.wait(forDuration: kAnimDelay),
            popAction,
            SKAction.wait(forDuration: kAnimDelay),
            popAction,
            SKAction.run {
                self.switchToGameOver()
            }
        ])
        run(pops)
    }
    
    /// 创建障碍物
    func createObstacle() -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: "Cactus")
        sprite.zPosition = Layer.Obstacle.rawValue
        sprite.userData = NSMutableDictionary()
        
        let offsetX = sprite.size.width * sprite.anchorPoint.x
        let offsetY = sprite.size.height * sprite.anchorPoint.y
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 3 - offsetX, y: 0 - offsetY))
        path.addLine(to: CGPoint(x: 5 - offsetX, y: 309 - offsetY))
        path.addLine(to: CGPoint(x: 16 - offsetX, y: 315 - offsetY))
        path.addLine(to: CGPoint(x: 39 - offsetX, y: 315 - offsetY))
        path.addLine(to: CGPoint(x: 51 - offsetX, y: 306 - offsetY))
        path.addLine(to: CGPoint(x: 49 - offsetX, y: 1 - offsetY))
        path.closeSubpath()
        
        sprite.physicsBody = SKPhysicsBody(polygonFrom: path)
        sprite.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
        sprite.physicsBody?.collisionBitMask = 0
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        return sprite
    }
    func setupMainMenu() {
        
        let logo = SKSpriteNode(imageNamed: "Logo")
        logo.position = CGPoint(x: size.width/2, y: size.height * 0.8)
        logo.zPosition = Layer.UI.rawValue
        worldNode.addChild(logo)
        
        // Play button
        let playButton = SKSpriteNode(imageNamed: "Button")
        playButton.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
        playButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(playButton)
        
        let play = SKSpriteNode(imageNamed: "Play")
        play.position = CGPoint.zero
        playButton.addChild(play)
        
        // Rate button
        let rateButton = SKSpriteNode(imageNamed: "Button")
        rateButton.position = CGPoint(x: size.width * 0.75, y: size.height * 0.25)
        rateButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(rateButton)
        
        let rate = SKSpriteNode(imageNamed: "Rate")
        rate.position = CGPoint.zero
        rateButton.addChild(rate)
        
        // Learn button
        let learn = SKSpriteNode(imageNamed: "button_learn")
        learn.position = CGPoint(x: size.width * 0.5, y: learn.size.height/2 + kMargin)
        learn.zPosition = Layer.UI.rawValue
        worldNode.addChild(learn)
        
        // Bounce button
        let scaleUp = SKAction.scale(to: 1.02, duration: 0.75)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 0.98, duration: 0.75)
        scaleDown.timingMode = .easeInEaseOut
        
        learn.run(SKAction.repeatForever(SKAction.sequence([
            scaleUp, scaleDown
            ])))
        
    }
    func setupTutorial() {
        
        let tutorial = SKSpriteNode(imageNamed: "Tutorial")
        tutorial.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.4 + playableStart)
        tutorial.name = "Tutorial"
        tutorial.zPosition = Layer.UI.rawValue
        worldNode.addChild(tutorial)
        
        let ready = SKSpriteNode(imageNamed: "Ready")
        ready.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.7 + playableStart)
        ready.name = "Tutorial"
        ready.zPosition = Layer.UI.rawValue
        worldNode.addChild(ready)
        
    }
    func setupPlayerAnimation() {
        var textures: Array<SKTexture> = []
        
        for i in 0..<4 {
            textures.append(SKTexture(imageNamed: "Bird\(i)"))
        }
        // 4=3-1
        for i in stride(from: 3, through: 0, by: -1) {
            textures.append(SKTexture(imageNamed: "Bird\(i)"))
        }
        
        let playerAnimation = SKAction.animate(with: textures, timePerFrame: 0.07)
        player.run(SKAction.repeatForever(playerAnimation))
        
    }
    func swpawnObstacle() {
        let bottomObstacle = createObstacle()
        bottomObstacle.name = "bottomObstacle"
        let startX = size.width + bottomObstacle.size.width/2
        // 计算障碍物超出地表的最小距离
        let bottomObstacleMin = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMinFraction
        // 计算障碍物超出地表的最大距离
        let bottomObstacleMax = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMaxFraction
        // 随机生成0.1~0.6的一个距离赋值给position
        bottomObstacle.position = CGPoint(x: startX, y: CGFloat.random(min: bottomObstacleMin, max: bottomObstacleMax))
        
        worldNode.addChild(bottomObstacle)
        
        let topObstacle = createObstacle()
        topObstacle.name = "topObstacle"
        topObstacle.zRotation = CGFloat(180).degreesToRadians()// 翻转180
        // 设置Y位置 相距3.5倍的player尺寸距离
        topObstacle.position = CGPoint(x: startX, y: bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + player.size.height * kGapMultiplier)
        
        worldNode.addChild(topObstacle)
        
        // 给障碍物添加动作
        let moveX = size.width + topObstacle.size.width
        let moveDuration = moveX / kGroundSpeed
        let sequence = SKAction.sequence([SKAction.moveBy(x: -moveX, y: 0, duration: TimeInterval(moveDuration)),SKAction.removeFromParent()])
        topObstacle.run(sequence)
        bottomObstacle.run(sequence)
        
    }
    /*
     第一个障碍物生成延迟1.75秒
     生成障碍物的动作，用到了先前的实例方法spawnObstacle.
     之后生成障碍物的间隔时间为1.5秒
     之后障碍物的生成顺序是:产生障碍物，延迟1.5秒;产生障碍物，延迟1.5秒;产生障碍物，延迟1.5秒...可以看出**[产生障碍物，延迟1.5秒]**为一组重复动作。
     使用SKAction.repeatActionForever重复4中的动作。
     将延迟1.75秒和重复动作整合成一个SKAction的数组，然后让场景来执行该动作组。
     */
    func startSpawning() {
        let firstDelay = SKAction.wait(forDuration: 1.75)
        let spawn = SKAction.run {
            self.swpawnObstacle()
        }
        let everyDelay = SKAction.wait(forDuration: 1.5)
        let spawnSequence = SKAction.sequence([spawn,everyDelay])
        
        let foreverSpawn = SKAction.repeatForever(spawnSequence)
        let overallSequence = SKAction.sequence([firstDelay,foreverSpawn])
        run(overallSequence,withKey: "spawn")
    }
    
    func stopSpawning() {
        removeAction(forKey: "spawn")
        worldNode.enumerateChildNodes(withName: "bottomObstacle") { (node, stop) in
            node.removeAllActions()
        }
        worldNode.enumerateChildNodes(withName: "topObstacle") { (node, stop) in
            node.removeAllActions()
        }
    }
    
    func updatePlayer() {
        // 只有Y轴上有加速度
        let gravity = CGPoint(x: 0, y: kGravity)
        let gravityStep = gravity * CGFloat(dt) // 计算dt时间速度的增量
        playerVelocity += gravityStep
        
        // 位置计算
        let velocityStep = playerVelocity * CGFloat(dt) // dt时间中下落或者上升距离
        player.position += velocityStep // 计算player的位置
        
        // 如果Player的Y坐标位置在地面上就不能再下落了，
        if player.position.y - player.size.height/2 < playableStart {
            player.position = CGPoint(x: player.position.x, y: playableStart + player.size.height/2)
        }
        
        if player.position.y < lastTouchY {
          playerAngularVelocity = -kAngularVelocity.degreesToRadians()
        }

        // Rotate player
        let angularStep = playerAngularVelocity * CGFloat(dt)
        player.zRotation += angularStep
        player.zRotation = min(max(player.zRotation, kMinDegrees.degreesToRadians()), kMaxDegrees.degreesToRadians())
    }
    
    func updateForeground() {
        worldNode.enumerateChildNodes(withName: "foreground") { (node, stop) in
            if let foreground = node as? SKSpriteNode {
                let moveAmt = CGPoint(x: -self.kGroundSpeed * CGFloat(self.dt),y: 0)
                foreground.position += moveAmt
                if foreground.position.x < -foreground.size.width {
                    foreground.position += CGPoint(x: foreground.size.width * 2, y: 0)
                }
            }
        }
    }
    /*
     起初场景中产生的障碍物都是携带的[]空字典内容。
     Player从一对障碍物的左侧穿越到右侧，才算"Passed",计分一次。
     检测方法很简单，只需要循环遍历worldNode节点中的所有障碍物，检查它的userData是否包含了Passed键值。两种情况:1.包含意味着当前障碍物已经经过且计算过分数了，所以无须再次累加，直接返回即可;2.当前障碍物为[]，说明还未被穿越过，因此需要通过位置检测(Player当前位置位于障碍物右侧?)，来判断是否穿越得分，是就分数累加且设置当前障碍物为已经"Passed"，否则什么都不处理，返回
     */
    func updateScore() {
        worldNode.enumerateChildNodes(withName: "bottomObstacle") { (node, stop) in
            if let obstacle = node as? SKSpriteNode {
                if let passed = obstacle.userData?["Passed"] as? Bool {
                    if passed {
                        return
                    }
                }
                if self.player.position.x > obstacle.position.x + obstacle.size.width/2 {
                    self.score += 1
                    self.scoreLabel.text = "\(self.score)"
                    self.run(self.coinAction)
                    obstacle.userData?["Passed"] = true
                }
            }
        }
    }
    
    /// 与障碍物发生碰撞
    func checkHitObstacle() {
        if hitObstacle {
            hitObstacle = false
            switchToFalling()
        }
    }
    
    func checkHitGround() {
        if hitGround {
            hitGround = false
            playerVelocity = .zero
            player.zRotation = CGFloat(-90).degreesToRadians()
            player.position = CGPoint(x: player.position.x, y: playableStart + player.size.width/2)
            run(hitGroundAction)
            switchToShowScore()
        }
    }
    
    // MARK: Game State
    //由play状态变为Falling状态
    func switchToFalling() {
        gameState = .Falling
        // Screen shake
        let shake = SKAction.screenShakeWithNode(node: worldNode, amount: CGPoint(x: 0, y: 7.0), oscillations: 10, duration: 1.0)
        worldNode.run(shake)
        
        // Flash
        let whiteNode = SKSpriteNode(color: SKColor.white, size: size)
        whiteNode.position = CGPoint(x: size.width/2, y: size.height/2)
        whiteNode.zPosition = Layer.Flash.rawValue
        worldNode.addChild(whiteNode)
        
        whiteNode.run(SKAction.removeFromParentAfterDelay(delay: 0.01))
        
        run(SKAction.sequence([
            whackAction,
            SKAction.wait(forDuration: 0.1),
            fallingAction
            ]))
        player.removeAllActions()
        stopSpawning()
    }
    // 显示分数
    func switchToShowScore() {
        gameState = .ShowingScore
        player.removeAllActions()
        stopSpawning()
        setupScoreCard()
    }
    // 重新开始一次游戏
    func switchToNewGame(_ state:GameState){
        run(popAction)
        
        let newScene = GameScene(size: size, gameState: state)
        let transition = SKTransition.fade(with: .black, duration: 0.5)
        view?.presentScene(newScene, transition: transition)
    }
    func switchToGameOver() {
        gameState = .GameOver
    }
    func switchToPlay() {
        gameState = .Play
        
        worldNode.enumerateChildNodes(withName: "Tutorial") { (node, stop) in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
        /// 开始产生障碍物
        startSpawning()
        /// 让player蹦跶一次
        flapPlayer()
    }
    
    func flapPlayer() {
        // 煽动翅膀的声音
        run(flapAction)
        // 重新设定player的速度！！
        playerVelocity = CGPoint(x: 0, y: kImpluse)
        
        playerAngularVelocity = kAngularVelocity.degreesToRadians()
        lastTouchTime = lastUpdateTime
        lastTouchY = player.position.y
        
        // 使得帽子下上跳动
        let moveUp = SKAction.moveBy(x: 0, y: 12, duration: 0.15)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        sombrero.run(SKAction.sequence([moveUp,moveDown]))
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        }else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        switch gameState {
        case .MainMenu:break
        case .Tutorial:break
        case .Play:
            updatePlayer()
            updateForeground()
            checkHitObstacle()
            checkHitGround()
            updateScore()
        case .Falling:
            updatePlayer()
            checkHitGround()
        case .ShowingScore:break
        case .GameOver:break
        }
        
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = (touch?.location(in: self))!
        switch gameState {
        case .MainMenu:
            if touchLocation.y < size.height * 0.15 {
                
            }else if touchLocation.x < size.width * 0.6{
                switchToNewGame(.Tutorial)
            }
            break
        case .Tutorial:
            switchToPlay()
            break
        case .Play:
            flapPlayer()
            break
        case .Falling:
            break
        case .ShowingScore:
            
            break
        case .GameOver:
            if touchLocation.x < size.width * 0.6 {
                switchToNewGame(.MainMenu)
            }
            break
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        
        if other.categoryBitMask == PhysicsCategory.Ground {
            hitGround = true
        }
        
        if other.categoryBitMask == PhysicsCategory.Obstacle {
            hitObstacle = true
        }
    }
     
    func bestScore() -> Int{
        return UserDefaults.standard.integer(forKey: "BestScore")
    }
    func setBsetScore(_ score:Int) {
        UserDefaults.standard.set(score, forKey: "BestScore")
        UserDefaults.standard.synchronize()
    }
}
