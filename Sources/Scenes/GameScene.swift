import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Game Objects
    var paddle: SKSpriteNode!
    var ball: SKSpriteNode!
    var bricks: [SKSpriteNode] = []
    var lasers: [SKSpriteNode] = []
    var enemyLasers: [SKSpriteNode] = []
    var boss: SKSpriteNode!
    var bossHealthFill: SKSpriteNode!
    
    // MARK: - Game State
    var ballVelocity: CGVector = .zero
    var isBallActive = false
    var isGameOver = false
    var score = 0
    var scoreLabel: SKLabelNode!
    var canShoot = true
    var level = 1
    var bossHealth = 100
    var maxBossHealth = 100
    var lastEnemyShotTime: TimeInterval = 0
    
    // MARK: - Constants
    let paddleWidth: CGFloat = 60
    let paddleHeight: CGFloat = 20
    let ballRadius: CGFloat = 10
    let brickRows = 3
    let brickCols = 6
    let brickHeight: CGFloat = 20
    let brickPadding: CGFloat = 5
    let laserSpeed: CGFloat = 500
    let enemyLaserSpeed: CGFloat = 300
    let shootCooldown: TimeInterval = 0.3
    let enemyShootInterval: TimeInterval = 1.5
    
    // MARK: - Colors
    let paddleColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
    let ballColor = UIColor.white
    let laserColor = UIColor.red
    let enemyLaserColor = UIColor.yellow
    let brickColors: [UIColor] = [
        UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.blue
    ]
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
        bricks.removeAll()
        lasers.removeAll()
        enemyLasers.removeAll()
        
        setupPaddle()
        setupBall()
        setupBoss()
        setupBricks()
        setupScoreLabel()
        
        let tapToStart = SKLabelNode(text: "Tap: Start | Shoot")
        tapToStart.name = "startLabel"
        tapToStart.fontSize = 24
        tapToStart.fontColor = .white
        tapToStart.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(tapToStart)
        
        isBallActive = false
        isGameOver = false
        score = 0
        canShoot = true
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
        let bossWidth: CGFloat = 120
        let bossHeight: CGFloat = 40
        
        boss = SKSpriteNode(color: bossColor, size: CGSize(width: bossWidth, height: bossHeight))
        boss.position = CGPoint(x: size.width / 2, y: size.height - 60)
        boss.name = "boss"
        addChild(boss)
        
        // Health bar
        let barWidth: CGFloat = 150
        let barHeight: CGFloat = 10
        bossHealthFill = SKSpriteNode(color: UIColor.green, size: CGSize(width: barWidth - 2, height: barHeight - 2))
        bossHealthFill.position = CGPoint(x: size.width / 2, y: size.height - 25)
        bossHealthFill.name = "bossHealthFill"
        addChild(bossHealthFill)
        
        maxBossHealth = 80 + (level - 1) * 30
        bossHealth = maxBossHealth
    }
    
    func setupBricks() {
        bricks.removeAll()
        let brickWidth = (size.width - CGFloat(brickCols + 1) * brickPadding) / CGFloat(brickCols)
        
        for row in 0..<brickRows {
            for col in 0..<brickCols {
                let brick = SKSpriteNode(
                    color: brickColors[row % brickColors.count],
                    size: CGSize(width: brickWidth - 2, height: brickHeight)
                )
                
                let x = brickPadding + brickWidth/2 + CGFloat(col) * (brickWidth + brickPadding)
                let y = size.height - 130 - brickHeight/2 - CGFloat(row) * (brickHeight + brickPadding)
                
                brick.position = CGPoint(x: x, y: y)
                brick.name = "brick"
                
                bricks.append(brick)
                addChild(brick)
            }
        }
    }
    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 15, y: size.height - 35)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
    }
    
    // MARK: - Shooting
    
    func shootLaser() {
        guard canShoot else { return }
        canShoot = false
        
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
        enemyLaser.position = CGPoint(x: boss.position.x + CGFloat.random(in: -20...20), y: boss.position.y - 30)
        enemyLaser.name = "enemyLaser"
        enemyLasers.append(enemyLaser)
        addChild(enemyLaser)
    }
    
    // MARK: - Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if isGameOver {
            setupGame()
            return
        }
        
        if !isBallActive {
            startBall()
            return
        }
        
        shootLaser()
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
    
    override func update(_ currentTime: TimeInterval) {
        guard isBallActive, !isGameOver else { return }
        
        let deltaTime = 1.0 / 60.0
        
        // Move ball
        ball.position.x += ballVelocity.dx * deltaTime
        ball.position.y += ballVelocity.dy * deltaTime
        
        // Wall collisions
        if ball.position.x - ballRadius < 0 {
            ball.position.x = ballRadius
            ballVelocity.dx = abs(ballVelocity.dx)
        }
        if ball.position.x + ballRadius > size.width {
            ball.position.x = size.width - ballRadius
            ballVelocity.dx = -abs(ballVelocity.dx)
        }
        
        let ceilingY = size.height * 0.90
        if ball.position.y + ballRadius > ceilingY {
            ball.position.y = ceilingY - ballRadius
            ballVelocity.dy = -abs(ballVelocity.dy)
        }
        
        // Boss collision
        if ball.frame.intersects(boss.frame) {
            ballVelocity.dy = -abs(ballVelocity.dy)
            damageBoss(5)
        }
        
        // Paddle collision
        if ball.frame.intersects(paddle.frame) && ballVelocity.dy < 0 {
            ballVelocity.dy = abs(ballVelocity.dy)
            let hitPoint = (ball.position.x - paddle.position.x) / (paddleWidth / 2)
            ballVelocity.dx += hitPoint * 100
        }
        
        // Brick collisions (ball)
        for brick in bricks {
            if ball.frame.intersects(brick.frame) {
                brick.removeFromParent()
                bricks.removeAll { $0 == brick }
                ballVelocity.dy = -ballVelocity.dy
                score += 5
                scoreLabel.text = "Score: \(score)"
                break
            }
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
            
            // Laser hits boss
            if laser.frame.intersects(boss.frame) {
                damageBoss(8)
                laser.removeFromParent()
                lasers.remove(at: i)
                continue
            }
            
            // Laser hits bricks
            for j in stride(from: bricks.count - 1, through: 0, by: -1) {
                if laser.frame.intersects(bricks[j].frame) {
                    bricks[j].removeFromParent()
                    bricks.remove(at: j)
                    laser.removeFromParent()
                    lasers.remove(at: i)
                    score += 5
                    scoreLabel.text = "Score: \(score)"
                    break
                }
            }
        }
        
        // Enemy lasers
        if currentTime - lastEnemyShotTime > enemyShootInterval / Double(level) {
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
            
            if enemyLaser.frame.intersects(paddle.frame) {
                enemyLaser.removeFromParent()
                enemyLasers.remove(at: i)
                gameOver()
                return
            }
        }
        
        // Ball falls
        if ball.position.y < 0 {
            gameOver()
        }
        
        // Win
        if bossHealth <= 0 {
            levelUp()
        }
    }
    
    func damageBoss(_ damage: Int) {
        bossHealth -= damage
        let percent = CGFloat(bossHealth) / CGFloat(maxBossHealth)
        let barWidth: CGFloat = 148
        bossHealthFill.size.width = max(0, barWidth * percent)
        
        if percent < 0.3 {
            bossHealthFill.color = .red
        } else if percent < 0.6 {
            bossHealthFill.color = .orange
        }
    }
    
    func levelUp() {
        level += 1
        score += 50 * level
        
        let levelLabel = SKLabelNode(text: "LEVEL \(level)!")
        levelLabel.fontSize = 40
        levelLabel.fontColor = .green
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(levelLabel)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            levelLabel.removeFromParent()
            self?.setupGame()
        }
    }
    
    func gameOver() {
        isBallActive = false
        isGameOver = true
        
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
