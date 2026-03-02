import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Game Objects
    var paddle: SKSpriteNode!
    var ball: SKSpriteNode!
    var lasers: [SKSpriteNode] = []
    var enemyLasers: [SKSpriteNode] = []
    var boss: SKSpriteNode!
    
    // MARK: - Game State
    var ballVelocity: CGVector = .zero
    var isBallActive = false
    var isGameOver = false
    var score = 0
    var scoreLabel: SKLabelNode!
    var canShoot = true
    var bossSpeed: CGFloat = 250
    var bossHP = 10
    var maxBossHP = 10
    var playerHP = 3
    var maxPlayerHP = 3
    var level = 1
    var lastEnemyShotTime: TimeInterval = 0
    var lastPlayerShotTime: TimeInterval = 0
    let playerShootInterval: TimeInterval = 0.4
    
    // Level settings
    var enemyShootInterval: TimeInterval = 0.6
    var enemyLaserSpeed: CGFloat = 350
    
    // MARK: - Constants
    let paddleWidth: CGFloat = 60
    let paddleHeight: CGFloat = 20
    let ballRadius: CGFloat = 10
    let laserSpeed: CGFloat = 500
    let shootCooldown: TimeInterval = 0.25
    
    // MARK: - Sound Effects
    var shootSound: SKAction!
    var hitBossSound: SKAction!
    var playerHitSound: SKAction!
    var levelUpSound: SKAction!
    var gameOverSound: SKAction!
    var laserHitSound: SKAction!
    
    func setupSounds() {
        // Load sound effects - check console for errors
        hitBossSound = SKAction.playSoundFileNamed("hit.wav", waitForCompletion: false)
        playerHitSound = SKAction.playSoundFileNamed("hurt.wav", waitForCompletion: false)
        levelUpSound = SKAction.playSoundFileNamed("levelup.wav", waitForCompletion: false)
        gameOverSound = SKAction.playSoundFileNamed("gameover.wav", waitForCompletion: false)
        laserHitSound = SKAction.playSoundFileNamed("laserhit.wav", waitForCompletion: false)
        shootSound = SKAction()
    }
    
    func playShoot() {
        run(shootSound)
    }
    
    func playHitBoss() {
        run(hitBossSound)
    }
    
    func playPlayerHit() {
        run(playerHitSound)
    }
    
    func playLevelUp() {
        run(levelUpSound)
    }
    
    func playGameOver() {
        run(gameOverSound)
    }
    
    func playLaserHit() {
        run(laserHitSound)
    }
    let paddleColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
    let ballColor = UIColor.white
    let laserColor = UIColor.red
    let enemyLaserColor = UIColor.yellow
    let bossColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        view.showsFPS = false
        view.showsNodeCount = false
        setupGame()
    }
    
    // MARK: - Setup
    
    func setupGame() {
        backgroundColor = SKColor.black
        
        removeAllChildren()
        lasers.removeAll()
        enemyLasers.removeAll()
        
        setupSounds()
        
        setupPaddle()
        setupBall()
        setupBoss()
        setupScoreLabel()
        
        let tapToStart = SKLabelNode(text: "Tap to Start")
        tapToStart.name = "startLabel"
        tapToStart.fontSize = 24
        tapToStart.fontColor = .white
        tapToStart.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(tapToStart)
        
        isBallActive = false
        isGameOver = false
        score = 0
        canShoot = true
        playerHP = 3
        maxPlayerHP = 3
        
        setupLevelParameters()
    }
    
    func setupLevelParameters() {
        // Level 1: HP=10, speed=250, fire=0.6s, laser=350
        // Level 2: HP=15, speed=300, fire=0.5s, laser=400
        // Level 3: HP=20, speed=350, fire=0.4s, laser=450
        // Level 4: HP=25, speed=400, fire=0.3s, laser=500
        // Level 5+: HP+=5, speed+=50, fire-0.05s, laser+=50
        
        maxBossHP = 10 + (level - 1) * 5
        bossHP = maxBossHP
        bossSpeed = 250 + CGFloat(level - 1) * 50
        enemyShootInterval = 0.6 - Double(level - 1) * 0.1
        if enemyShootInterval < 0.2 { enemyShootInterval = 0.2 }
        enemyLaserSpeed = 350 + CGFloat(level - 1) * 50
    }
    
    func setupPaddle() {
        paddle = SKSpriteNode(color: paddleColor, size: CGSize(width: paddleWidth, height: paddleHeight))
        paddle.position = CGPoint(x: size.width / 2, y: 100)
        paddle.name = "paddle"
        addChild(paddle)
    }
    
    func setupBall() {
        ball = SKSpriteNode(color: ballColor, size: CGSize(width: ballRadius * 2, height: ballRadius * 2))
        ball.position = CGPoint(x: size.width / 2, y: 140)
        ball.name = "ball"
        addChild(ball)
    }
    
    func setupBoss() {
        let bossWidth: CGFloat = 70
        let bossHeight: CGFloat = 20
        
        boss = SKSpriteNode(color: bossColor, size: CGSize(width: bossWidth, height: bossHeight))
        boss.position = CGPoint(x: size.width / 2, y: size.height - 60)
        boss.name = "boss"
        addChild(boss)
    }
    
    func updateBossAppearance() {
        let bossWidth: CGFloat = 70
        let percent = CGFloat(bossHP) / CGFloat(maxBossHP)
        
        // Boss shrinks as HP decreases
        boss.size.width = bossWidth * percent
        
        // Color changes: green -> yellow -> red
        if percent > 0.6 {
            boss.color = UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0) // green
        } else if percent > 0.3 {
            boss.color = UIColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0) // yellow
        } else {
            boss.color = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) // red
        }
    }
    
    func updatePaddleAppearance() {
        let paddleMaxWidth: CGFloat = 60
        let percent = CGFloat(playerHP) / CGFloat(maxPlayerHP)
        
        // Paddle shrinks as HP decreases
        paddle.size.width = paddleMaxWidth * percent
        
        // Color changes: blue -> yellow -> red
        if percent > 0.6 {
            paddle.color = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0) // blue
        } else if percent > 0.3 {
            paddle.color = UIColor(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0) // yellow
        } else {
            paddle.color = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) // red
        }
    }
    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Lv.\(level) | Score: \(score)")
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 15, y: size.height - 30)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
    }
    
    // MARK: - Shooting
    
    func shootLaser() {
        guard canShoot else { return }
        canShoot = false
        
        // No sound - too annoying with auto-shoot!
        
        let laser = SKSpriteNode(color: laserColor, size: CGSize(width: 3, height: 15))
        laser.position = CGPoint(x: paddle.position.x, y: paddle.position.y + paddleHeight)
        laser.name = "laser"
        lasers.append(laser)
        addChild(laser)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + shootCooldown) { [weak self] in
            self?.canShoot = true
        }
    }
    
    func enemyShoot() {
        guard !isGameOver else { return }
        
        let enemyLaser = SKSpriteNode(color: enemyLaserColor, size: CGSize(width: 5, height: 10))
        enemyLaser.position = CGPoint(x: boss.position.x + CGFloat.random(in: -10...10), y: boss.position.y - 15)
        enemyLaser.name = "enemyLaser"
        enemyLasers.append(enemyLaser)
        addChild(enemyLaser)
    }
    
    // MARK: - Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if isGameOver {
            if childNode(withName: "nextLevel") != nil {
                // Level up!
                level += 1
                let currentLevel = level
                setupGame()
                level = currentLevel
            } else {
                // Full restart
                level = 1
                setupGame()
            }
            return
        }
        
        if !isBallActive {
            startBall()
            return
        }
        
        movePaddle(to: touch.location(in: self).x)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isBallActive, let touch = touches.first else { return }
        movePaddle(to: touch.location(in: self).x)
    }
    
    func movePaddle(to x: CGFloat) {
        paddle.position.x = max(paddleWidth/2, min(size.width - paddleWidth/2, x))
    }
    
    // MARK: - Game Logic
    
    func startBall() {
        isBallActive = true
        childNode(withName: "startLabel")?.removeFromParent()
        
        let angle = CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
        let speed: CGFloat = 400
        ballVelocity = CGVector(dx: cos(angle) * speed, dy: abs(sin(angle)) * speed)
    }
    
    // MARK: - Boss AI
    
    func updateBossAI() {
        let bossWidth: CGFloat = 70
        
        // Ball is going up - try to intercept like a paddle!
        if ballVelocity.dy > 0 {
            // Calculate where ball will be when it reaches boss level
            let timeToBoss = (boss.position.y - ball.position.y) / ballVelocity.dy
            let predictedX = ball.position.x + ballVelocity.dx * timeToBoss
            
            // Move to intercept
            if predictedX > boss.position.x + 5 {
                boss.position.x += bossSpeed * (1/60)
            } else if predictedX < boss.position.x - 5 {
                boss.position.x -= bossSpeed * (1/60)
            }
        } else {
            // Ball going down - return to center slowly
            let centerX = size.width / 2
            if centerX > boss.position.x + 20 {
                boss.position.x += (bossSpeed * 0.5) * (1/60)
            } else if centerX < boss.position.x - 20 {
                boss.position.x -= (bossSpeed * 0.5) * (1/60)
            }
        }
        
        // Avoid lasers coming up!
        for laser in lasers {
            if laser.position.y > boss.position.y - 40 && laser.position.y < boss.position.y + 20 {
                if laser.position.x < boss.position.x && boss.position.x < size.width - bossWidth/2 {
                    boss.position.x += bossSpeed * 0.9 * (1/60)
                } else if laser.position.x > boss.position.x && boss.position.x > bossWidth/2 {
                    boss.position.x -= bossSpeed * 0.9 * (1/60)
                }
            }
        }
        
        // Keep boss in bounds
        boss.position.x = max(bossWidth/2, min(size.width - bossWidth/2, boss.position.x))
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isBallActive, !isGameOver else { return }
        
        let deltaTime = 1.0 / 60.0
        
        // Update Boss AI
        updateBossAI()
        
        // Auto shoot lasers
        if currentTime - lastPlayerShotTime > playerShootInterval {
            shootLaser()
            lastPlayerShotTime = currentTime
        }
        
        // Move ball
        ball.position.x += ballVelocity.dx * deltaTime
        ball.position.y += ballVelocity.dy * deltaTime
        
        // Wall collisions (left/right)
        if ball.position.x - ballRadius < 0 {
            ball.position.x = ballRadius
            ballVelocity.dx = abs(ballVelocity.dx)
        }
        if ball.position.x + ballRadius > size.width {
            ball.position.x = size.width - ballRadius
            ballVelocity.dx = -abs(ballVelocity.dx)
        }
        
        // Ball passes boss - YOU WIN!
        if ball.position.y > boss.position.y + 30 {
            winGame()
            return
        }
        
        // Boss collision - bounces ball back down!
        let bossWidth: CGFloat = 70
        let bossHeight: CGFloat = 20
        let bossFrame = CGRect(x: boss.position.x - bossWidth/2, y: boss.position.y - bossHeight/2, width: bossWidth, height: bossHeight)
        
        if ball.frame.intersects(bossFrame) {
            ballVelocity.dy = -abs(ballVelocity.dy)
            let hitPoint = (ball.position.x - boss.position.x) / (bossWidth / 2)
            ballVelocity.dx += hitPoint * 120
            ball.position.y = boss.position.y - bossHeight/2 - ballRadius - 1
        }
        
        // Paddle collision
        if ball.frame.intersects(paddle.frame) && ballVelocity.dy < 0 {
            ballVelocity.dy = abs(ballVelocity.dy)
            let hitPoint = (ball.position.x - paddle.position.x) / (paddleWidth / 2)
            ballVelocity.dx += hitPoint * 100
        }
        
        // Player lasers
        for i in stride(from: lasers.count - 1, through: 0, by: -1) {
            let laser = lasers[i]
            laser.position.y += laserSpeed * deltaTime
            
            if laser.position.y > size.height {
                laser.removeFromParent()
                lasers.remove(at: i)
                continue
            }
            
            // Ball bounces off laser
            if ball.frame.intersects(laser.frame) {
                playLaserHit()
                ballVelocity.dy = abs(ballVelocity.dy)
                ballVelocity.dx += CGFloat.random(in: -30...30)
                laser.removeFromParent()
                lasers.remove(at: i)
                score += 5
                scoreLabel.text = "Lv.\(level) | Score: \(score)"
                continue
            }
            
            // Laser hits boss - DAMAGE BOSS!
            if laser.frame.intersects(bossFrame) {
                playHitBoss()
                laser.removeFromParent()
                lasers.remove(at: i)
                bossHP -= 1
                updateBossAppearance()
                score += 10
                scoreLabel.text = "Lv.\(level) | Score: \(score)"
                
                // Flash boss
                boss.alpha = 0.5
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.boss.alpha = 1.0
                }
                
                if bossHP <= 0 {
                    winGame()
                    return
                }
                continue
            }
        }
        
        // Enemy lasers
        if currentTime - lastEnemyShotTime > enemyShootInterval {
            enemyShoot()
            lastEnemyShotTime = currentTime
        }
        
        for i in stride(from: enemyLasers.count - 1, through: 0, by: -1) {
            let enemyLaser = enemyLasers[i]
            enemyLaser.position.y -= enemyLaserSpeed * deltaTime
            
            if enemyLaser.position.y < 0 {
                enemyLaser.removeFromParent()
                enemyLasers.remove(at: i)
                continue
            }
            
            // Enemy laser - hits ball from below and boosts it up!
            if enemyLaser.frame.intersects(ball.frame) {
                enemyLaser.removeFromParent()
                enemyLasers.remove(at: i)
                // Boost ball upward
                ballVelocity.dy = abs(ballVelocity.dy) * 1.3
                ballVelocity.dx += CGFloat.random(in: -20...20)
                continue
            }
            
            // Enemy laser hits paddle - lose HP!
            if enemyLaser.frame.intersects(paddle.frame) {
                enemyLaser.removeFromParent()
                enemyLasers.remove(at: i)
                
                playerHP -= 1
                playPlayerHit()
                updatePaddleAppearance()
                
                // Flash paddle
                paddle.alpha = 0.5
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.paddle.alpha = 1.0
                }
                
                if playerHP <= 0 {
                    gameOver()
                    return
                }
                continue
            }
        }
        
        // Ball falls below paddle - lose HP!
        if ball.position.y < 0 {
            playerHP -= 1
            playPlayerHit()
            updatePaddleAppearance()
            
            // Flash paddle
            paddle.alpha = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.paddle.alpha = 1.0
            }
            
            if playerHP <= 0 {
                gameOver()
            } else {
                // Reset ball position
                ball.position = CGPoint(x: size.width / 2, y: 140)
                ballVelocity = .zero
                isBallActive = false
                
                // Show tap to continue
                let tapToContinue = SKLabelNode(text: "Tap to Continue")
                tapToContinue.name = "startLabel"
                tapToContinue.fontSize = 24
                tapToContinue.fontColor = .white
                tapToContinue.position = CGPoint(x: size.width / 2, y: size.height / 2)
                addChild(tapToContinue)
            }
        }
    }
    
    func winGame() {
        isBallActive = false
        isGameOver = true
        
        playLevelUp()
        
        let levelUpLabel = SKLabelNode(text: "LEVEL \(level) COMPLETE!")
        levelUpLabel.fontSize = 36
        levelUpLabel.fontColor = .green
        levelUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        addChild(levelUpLabel)
        
        let nextLabel = SKLabelNode(text: "Tap for Level \(level + 1)")
        nextLabel.fontSize = 20
        nextLabel.fontColor = .white
        nextLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        nextLabel.name = "nextLevel"
        addChild(nextLabel)
    }
    
    func gameOver() {
        isBallActive = false
        isGameOver = true
        
        playGameOver()
        
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 20
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        restartLabel.name = "restart"
        addChild(restartLabel)
    }
}
