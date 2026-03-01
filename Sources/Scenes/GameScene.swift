import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Game Objects
    var paddle: SKSpriteNode!
    var ball: SKSpriteNode!
    var bricks: [SKSpriteNode] = []
    
    // MARK: - Game State
    var ballVelocity: CGVector = .zero
    var isBallActive = false
    var score = 0
    var scoreLabel: SKLabelNode!
    
    // MARK: - Constants
    let paddleWidth: CGFloat = 100
    let paddleHeight: CGFloat = 20
    let ballRadius: CGFloat = 10
    let brickRows = 5
    let brickCols = 8
    let brickHeight: CGFloat = 25
    let brickPadding: CGFloat = 5
    
    // MARK: - Colors
    let paddleColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 1.0)
    let ballColor = UIColor.white
    let brickColors: [UIColor] = [
        UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.blue
    ]
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        print("Scene size: \(size.width) x \(size.height)")
        setupGame()
    }
    
    // MARK: - Setup
    
    func setupGame() {
        backgroundColor = SKColor.black
        
        setupPaddle()
        setupBall()
        setupBricks()
        setupScoreLabel()
        
        // Start ball on tap
        let tapToStart = SKLabelNode(text: "Tap to Start")
        tapToStart.name = "startLabel"
        tapToStart.fontSize = 30
        tapToStart.fontColor = .white
        tapToStart.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(tapToStart)
        
        print("Paddle at: \(paddle.position)")
        print("Ball at: \(ball.position)")
        print("Bricks count: \(bricks.count)")
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
    
    func setupBricks() {
        let brickWidth = (size.width - CGFloat(brickCols + 1) * brickPadding) / CGFloat(brickCols)
        
        for row in 0..<brickRows {
            for col in 0..<brickCols {
                let brick = SKSpriteNode(
                    color: brickColors[row % brickColors.count],
                    size: CGSize(width: brickWidth - 2, height: brickHeight)
                )
                
                let x = brickPadding + brickWidth/2 + CGFloat(col) * (brickWidth + brickPadding)
                let y = size.height - 100 - brickHeight/2 - CGFloat(row) * (brickHeight + brickPadding)
                
                brick.position = CGPoint(x: x, y: y)
                brick.name = "brick"
                brick.alpha = 1.0
                
                bricks.append(brick)
                addChild(brick)
            }
        }
    }
    
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 20, y: size.height - 40)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
    }
    
    // MARK: - Input
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if !isBallActive {
            startBall()
        } else {
            movePaddle(to: location.x)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isBallActive, let touch = touches.first else { return }
        let location = touch.location(in: self)
        movePaddle(to: location.x)
    }
    
    func movePaddle(to x: CGFloat) {
        paddle.position.x = max(paddleWidth/2, min(size.width - paddleWidth/2, x))
    }
    
    // MARK: - Game Logic
    
    func startBall() {
        isBallActive = true
        childNode(withName: "startLabel")?.removeFromParent()
        
        // Random initial direction going up
        let angle = CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
        let speed: CGFloat = 300
        ballVelocity = CGVector(dx: cos(angle) * speed, dy: abs(sin(angle)) * speed)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isBallActive else { return }
        
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
        if ball.position.y + ballRadius > size.height {
            ball.position.y = size.height - ballRadius
            ballVelocity.dy = -abs(ballVelocity.dy)
        }
        
        // Paddle collision
        if ball.frame.intersects(paddle.frame) && ballVelocity.dy < 0 {
            ballVelocity.dy = abs(ballVelocity.dy)
            
            // Add angle based on where ball hits paddle
            let hitPoint = (ball.position.x - paddle.position.x) / (paddleWidth / 2)
            ballVelocity.dx += hitPoint * 150
        }
        
        // Brick collisions
        for brick in bricks {
            if ball.frame.intersects(brick.frame) {
                brick.removeFromParent()
                bricks.removeAll { $0 == brick }
                
                // Simple bounce
                ballVelocity.dy = -ballVelocity.dy
                
                // Score
                score += 10
                scoreLabel.text = "Score: \(score)"
                
                break
            }
        }
        
        // Game over - ball falls
        if ball.position.y < 0 {
            gameOver()
        }
        
        // Win condition
        if bricks.isEmpty {
            winGame()
        }
    }
    
    func gameOver() {
        isBallActive = false
        
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(text: "Tap to Restart")
        restartLabel.fontSize = 24
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        restartLabel.name = "restart"
        addChild(restartLabel)
    }
    
    func winGame() {
        isBallActive = false
        
        let winLabel = SKLabelNode(text: "You Win!")
        winLabel.fontSize = 48
        winLabel.fontColor = .green
        winLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(winLabel)
        
        let restartLabel = SKLabelNode(text: "Tap to Play Again")
        restartLabel.fontSize = 24
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        restartLabel.name = "restart"
        addChild(restartLabel)
    }
}
