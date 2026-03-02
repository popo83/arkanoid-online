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
    var highScore = 0
    var scoreLabel: SKLabelNode!
    var canShoot = true
    var bossSpeed: CGFloat = 250
    var bossHP = 10
    var maxBossHP = 10
    var playerHP = 3
    var maxPlayerHP = 3
    var level = 1
    var infiniteHP = false
    var gameState = "menu" // menu, playing, gameover
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
    let maxBallSpeed: CGFloat = 800
    
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
    let laserColor = UIColor.yellow  // Player lasers
    let enemyLaserColor = UIColor.red  // Boss lasers
    let bossColor = UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        view.showsFPS = false
        view.showsNodeCount = false
        // Load high score
        highScore = UserDefaults.standard.integer(forKey: "highScore")
        showMenu()
    }
    
    func showMenu() {
        gameState = "menu"
        backgroundColor = SKColor.black
        removeAllChildren()
        
        // Title
        let titleLabel = SKLabelNode(text: "AInoid")
        titleLabel.fontSize = 48
        titleLabel.fontColor = .cyan
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        addChild(titleLabel)
        
        let subtitleLabel = SKLabelNode(text: "Challenge the AI")
        subtitleLabel.fontSize = 24
        subtitleLabel.fontColor = .green
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        addChild(subtitleLabel)
        
        // High Score
        let hsLabel = SKLabelNode(text: "HIGH SCORE: \(highScore)")
        hsLabel.fontSize = 22
        hsLabel.fontColor = .yellow
        hsLabel.position = CGPoint(x: size.width / 2, y: size.height - 220)
        addChild(hsLabel)
        
        // Start Button
        let startButton = SKLabelNode(text: "TAP TO START")
        startButton.name = "startButton"
        startButton.fontSize = 28
        startButton.fontColor = .green
        startButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(startButton)
        
        // DEBUG: Infinite HP Button (bottom center)
        let debugButton = SKLabelNode(text: "DEBUG: INFINITE HP")
        debugButton.name = "debugInfiniteHP"
        debugButton.fontSize = 14
        debugButton.fontColor = .red
        debugButton.position = CGPoint(x: size.width / 2, y: 50)
        addChild(debugButton)
        
        // Instructions
        let instrLabel = SKLabelNode(text: "Developed by J4K08")
        instrLabel.fontSize = 14
        instrLabel.fontColor = .gray
        instrLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        addChild(instrLabel)
    }
    
    // MARK: - Setup
    
    func setupGame() {
        gameState = "playing"
        backgroundColor = SKColor.black
        // Level stays the same on level up! (handled in touchesBegan)
        
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
        // Boss starts with 10 HP, +5 per level
        maxBossHP = min(10 + (level - 1) * 5, 50)  // +5/lvl, max 50
        bossHP = maxBossHP
        bossSpeed = 250 + CGFloat(level - 1) * 80  // Reduced from 120
        enemyShootInterval = 0.8 - Double(level - 1) * 0.05  // Reduced from 0.07
        if enemyShootInterval < 0.10 { enemyShootInterval = 0.10 }  // Higher min (was 0.06)
        enemyLaserSpeed = 350 + CGFloat(level - 1) * 80  // Reduced from 120
    }
    
    func setupPaddle() {
        paddle = SKSpriteNode(color: paddleColor, size: CGSize(width: paddleWidth, height: paddleHeight))
        paddle.position = CGPoint(x: self.size.width * 0.5, y: self.size.height * 0.14)
        paddle.size = CGSize(width: self.size.width * 0.2, height: 15)
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
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 15, y: size.height - 70)  // Top left
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        // Boss HP Label
        let bossHPLabel = SKLabelNode(text: "Boss: \(bossHP)/\(maxBossHP)")
        bossHPLabel.name = "bossHPLabel"
        bossHPLabel.fontSize = 16
        bossHPLabel.fontColor = .red
        bossHPLabel.position = CGPoint(x: 15, y: size.height - 100)  // Below score
        bossHPLabel.horizontalAlignmentMode = .left
        addChild(bossHPLabel)
        
        // DEBUG PANEL - Only show when infiniteHP is ON
        if infiniteHP {
            let aiLevel = level
            let aiAccuracy = 0.90 + Double(aiLevel) * 0.01
            let mistakeChance = max(0.30 - (Double(aiLevel) - 1) * 0.05, 0.02)
            let debugText = "LV:\(level) HP:\(bossHP) BS:\(Int(bossSpeed))\nFR:\(String(format: "%.2f", enemyShootInterval)) LS:\(Int(enemyLaserSpeed))"
            let debugLabel = SKLabelNode(text: debugText)
            debugLabel.name = "debugLabel"
            debugLabel.fontSize = 20
            debugLabel.fontColor = .yellow
            debugLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
            addChild(debugLabel)
            
            // AI DEBUG PANEL
            let aiText = "AI ACC:\(String(format: "%.0f", aiAccuracy*100))% ERR:\(String(format: "%.0f", mistakeChance*100))% L:\(aiLevel)"
            let aiLabel = SKLabelNode(text: aiText)
            aiLabel.name = "aiLabel"
            aiLabel.fontSize = 18
            aiLabel.fontColor = .cyan
            aiLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
            addChild(aiLabel)
        }
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
        
        // Menu state
        if gameState == "menu" {
            let touchLocation = touch.location(in: self)
            if let debugBtn = childNode(withName: "debugInfiniteHP") as? SKLabelNode {
                let btnFrame = CGRect(
                    x: debugBtn.position.x - 100,
                    y: debugBtn.position.y - 15,
                    width: 200,
                    height: 30
                )
                if btnFrame.contains(touchLocation) {
                    infiniteHP = !infiniteHP
                    debugBtn.text = infiniteHP ? "INFINITE HP: ON" : "DEBUG: INFINITE HP"
                    debugBtn.fontColor = infiniteHP ? .green : .red
                    return
                }
            }
            gameState = "playing"
            setupGame()
            return
        }
        
        if isGameOver {
            if childNode(withName: "nextLevel") != nil {
                // Level up!
                let savedScore = score
                let savedPlayerHP = playerHP
                level += 1
                setupLevelParameters()  // Reset boss HP for new level!
                let currentLevel = level
                setupGame()
                level = currentLevel
                score = savedScore
                playerHP = savedPlayerHP
                updatePaddleAppearance()
                scoreLabel.text = "Lv.\(level) | Score: \(score)"
            } else {
                // Go to menu - reset EVERYTHING
                level = 1
                score = 0
                playerHP = 3
                showMenu()
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
        guard gameState == "playing", isBallActive, let touch = touches.first else { return }
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
    
    func clampBallSpeed() {
        let speed = sqrt(ballVelocity.dx * ballVelocity.dx + ballVelocity.dy * ballVelocity.dy)
        if speed > maxBallSpeed {
            let scale = maxBallSpeed / speed
            ballVelocity.dx *= scale
            ballVelocity.dy *= scale
        }
    }
    
    func clearAllLasers() {
        for laser in lasers {
            laser.removeFromParent()
        }
        lasers.removeAll()
        
        for enemyLaser in enemyLasers {
            enemyLaser.removeFromParent()
        }
        enemyLasers.removeAll()
    }
    
    func createExplosion(at position: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 50
        emitter.numParticlesToEmit = 20
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.3
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.5
        emitter.particleAlphaSpeed = -1.0
        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = .red
        emitter.particleColorBlendFactor = 1.0
        emitter.position = position
        emitter.targetNode = self
        addChild(emitter)
        let wait = SKAction.wait(forDuration: 1.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
    
    // MARK: - Boss AI
    
    func updateBossAI() {
        let bossWidth: CGFloat = 70
        
        // AI evolves with levels!
        // Level 1-2: Basic AI, predictable
        // Level 3-4: Starts dodging lasers, more precise
        // Level 5+: Aggressive, rare mistakes
        // Level 10+: Almost impossible
        
        let aiLevel = level  // No cap - keeps getting harder!
        let aiLevelDouble = Double(aiLevel)
        
        // Calculate AI skill (0.0 to 1.0) - unlimited!
        let aiSkill = aiLevelDouble / 10.0
        
        // Error chance decreases FASTER with level
        let mistakeChance = max(0.30 - (aiLevelDouble - 1) * 0.05, 0.02)  // 30% at lvl 1, 2% at lvl 8+
        let makeMistake = Double.random(in: 0...1) < mistakeChance
        
        // Precision improves with level
        let predictionAccuracy = 0.90 + aiLevelDouble * 0.01  // 90% + 1% per level (was 74%)
        
        // Laser dodge at level 6+
        
        // Ball is going up - try to intercept!
        if ballVelocity.dy > 0 {
            let timeToBoss = (boss.position.y - ball.position.y) / max(ballVelocity.dy, 1)
            var predictedX = ball.position.x + ballVelocity.dx * timeToBoss * predictionAccuracy
            
            // Add error if making mistake
            if makeMistake {
                predictedX += CGFloat.random(in: -60...60)
            }
            
            // Move to intercept
            let speedMultiplier = makeMistake ? 0.6 : 1.0
            if predictedX > boss.position.x + 5.0 {
                boss.position.x += CGFloat(bossSpeed * speedMultiplier * (1.0/60.0))
            } else if predictedX < boss.position.x - 5.0 {
                boss.position.x -= CGFloat(bossSpeed * speedMultiplier * (1.0/60.0))
            }
            
        } else {
            // Ball going down - return to center
            let centerX = size.width / 2
            let returnSpeed = bossSpeed * (makeMistake ? 0.3 : 0.6)
            
            if centerX > boss.position.x + 20.0 {
                boss.position.x += CGFloat(returnSpeed * (1.0/60.0))
            } else if centerX < boss.position.x - 20.0 {
                boss.position.x -= CGFloat(returnSpeed * (1.0/60.0))
            }
        }
        
        // Dodge lasers (level 6+) - reduced effectiveness
        if aiLevel >= 6 {
            for laser in lasers {
                if laser.position.y > boss.position.y - 60 && laser.position.y < boss.position.y + 30 {
                    let dodgeSpeed = bossSpeed * (makeMistake ? 0.4 : 0.7)
                    if laser.position.x < boss.position.x && boss.position.x < size.width - bossWidth/2 {
                        boss.position.x += CGFloat(dodgeSpeed * (1.0/60.0))
                    } else if laser.position.x > boss.position.x && boss.position.x > bossWidth/2 {
                        boss.position.x -= CGFloat(dodgeSpeed * (1.0/60.0))
                    }
                }
            }
        }
        
        // Keep boss in bounds
        boss.position.x = max(bossWidth/2, min(size.width - bossWidth/2, boss.position.x))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Update debug panels (only when infiniteHP is ON)
        if infiniteHP {
            let aiLevel = level
            let aiAccuracy = 0.90 + Double(aiLevel) * 0.01
            let mistakeChance = max(0.30 - (Double(aiLevel) - 1) * 0.05, 0.02)
            if let debug = childNode(withName: "debugLabel") as? SKLabelNode {
                debug.text = "LV:\(level) HP:\(bossHP) BS:\(Int(bossSpeed))\nFR:\(String(format: "%.2f", enemyShootInterval)) LS:\(Int(enemyLaserSpeed))"
            }
            if let aiLabel = childNode(withName: "aiLabel") as? SKLabelNode {
                aiLabel.text = "AI ACC:\(String(format: "%.0f", aiAccuracy*100))% ERR:\(String(format: "%.0f", mistakeChance*100))% L:\(aiLevel)"
            }
        }
        
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
        
        // Prevent ball from bouncing too horizontally
        let minVerticalSpeed: CGFloat = 150
        if abs(ballVelocity.dy) < minVerticalSpeed {
            // Force minimum vertical velocity in current direction
            if ballVelocity.dy >= 0 {
                ballVelocity.dy = minVerticalSpeed
            } else {
                ballVelocity.dy = -minVerticalSpeed
            }
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
                if let bossHPLabel = childNode(withName: "bossHPLabel") as? SKLabelNode {
                    bossHPLabel.text = "Boss: \(bossHP)/\(maxBossHP)"
                }
                score += 10
                scoreLabel.text = "Lv.\(level) | Score: \(score)"
                
                // Flash boss
                boss.alpha = 0.5
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.boss.alpha = 1.0
                }
                
                // Particle explosion
                createExplosion(at: CGPoint(x: laser.position.x, y: boss.position.y))
                
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
            
            // Enemy laser - hits ball from below and sends it DOWN faster!
            if enemyLaser.frame.intersects(ball.frame) {
                playLaserHit()
                enemyLaser.removeFromParent()
                enemyLasers.remove(at: i)
                // Send ball DOWN with increased speed
                let speedBoost: CGFloat = 1.5
                ballVelocity.dy = -abs(ballVelocity.dy) * speedBoost
                ballVelocity.dx = ballVelocity.dx * speedBoost
                clampBallSpeed()
                continue
            }
            
            // Enemy laser hits paddle - lose HP or bounce
            if enemyLaser.frame.intersects(paddle.frame) {
                enemyLaser.removeFromParent()
                enemyLasers.remove(at: i)
                
                if infiniteHP {
                    // Just bounce ball up
                    ballVelocity.dy = abs(ballVelocity.dy)
                    ballVelocity.dx += CGFloat.random(in: -30...30)
                } else {
                    playerHP -= 1
                    playPlayerHit()
                    updatePaddleAppearance()
                    clearAllLasers()
                    
                    // Flash paddle
                    paddle.alpha = 0.5
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.paddle.alpha = 1.0
                    }
                    
                    if playerHP <= 0 {
                        gameOver()
                        return
                    }
                }
                continue
            }
        }
        
        // Ball falls below paddle - lose HP!
        if ball.position.y < 0 {
            if infiniteHP {
                // Reset ball position only
                ball.position = CGPoint(x: size.width / 2, y: 140)
                ballVelocity = .zero
                isBallActive = false
                
                let tapToContinue = SKLabelNode(text: "Tap to Continue")
                tapToContinue.name = "startLabel"
                tapToContinue.fontSize = 24
                tapToContinue.fontColor = .white
                tapToContinue.position = CGPoint(x: size.width / 2, y: size.height / 2)
                addChild(tapToContinue)
            } else {
                playerHP -= 1
                playPlayerHit()
                updatePaddleAppearance()
                clearAllLasers()
                
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
        gameState = "gameover"
        
        // Save high score (only if not in infinite HP mode)
        if score > highScore && !infiniteHP {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
        
        playGameOver()
        
        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        addChild(gameOverLabel)
        
        // Current score
        let scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        addChild(scoreLabel)
        
        // High score
        let hsLabel = SKLabelNode(text: "High Score: \(highScore)")
        hsLabel.fontSize = 20
        hsLabel.fontColor = .yellow
        hsLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        addChild(hsLabel)
        
        let menuLabel = SKLabelNode(text: "Tap for Menu")
        menuLabel.fontSize = 20
        menuLabel.fontColor = .gray
        menuLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 90)
        menuLabel.name = "menu"
        addChild(menuLabel)
    }
}
