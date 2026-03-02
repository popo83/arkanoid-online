import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var skView: SKView!
    var gameScene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Remove safe area insets for fullscreen
        edgesForExtendedLayout = []
        
        // Full screen
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        // Create scene with screen size
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        gameScene = GameScene(size: CGSize(width: screenWidth, height: screenHeight))
        gameScene.scaleMode = .resizeFill
        
        skView.presentScene(gameScene)
        view.addSubview(skView)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
