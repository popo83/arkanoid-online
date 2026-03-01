import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    var skView: SKView!
    var gameScene: GameScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        // Create scene with a fixed size
        gameScene = GameScene(size: CGSize(width: 390, height: 844))
        gameScene.scaleMode = .aspectFill
        
        skView.presentScene(gameScene)
        view.addSubview(skView)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
