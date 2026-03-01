import UIKit
import SpriteKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create a simple view controller
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        
        // Create SKView
        let skView = SKView(frame: window!.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let gameScene = GameScene(size: skView.bounds.size)
        gameScene.scaleMode = .aspectFill
        
        skView.presentScene(gameScene)
        
        viewController.view.addSubview(skView)
        
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
}
