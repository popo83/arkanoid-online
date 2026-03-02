import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController, GKGameCenterControllerDelegate {
    
    var skView: SKView!
    var gameScene: GameScene!
    let leaderboardID = "4IN01D_Leaderboard"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authenticateGameCenter()
        
        // Extend under safe areas
        edgesForExtendedLayout = [.top, .bottom]
        view.insetsLayoutMarginsFromSafeArea = false
        
        // Full screen SKView
        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.translatesAutoresizingMaskIntoConstraints = true
        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        
        // Create scene with screen size
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        gameScene = GameScene(size: CGSize(width: screenWidth, height: screenHeight))
        gameScene.scaleMode = .resizeFill
        gameScene.viewController = self
        
        skView.presentScene(gameScene)
        view.addSubview(skView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        skView.frame = view.bounds
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // MARK: - Game Center
    func authenticateGameCenter() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { [weak self] viewController, error in
            if let vc = viewController {
                self?.present(vc, animated: true)
            } else if let error = error {
                print("Game Center auth error: \(error.localizedDescription)")
            }
        }
    }
    
    func submitScoreToLeaderboard(_ score: Int) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Submit score error: \(error.localizedDescription)")
            }
        }
    }
    
    func showLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else {
            authenticateGameCenter()
            return
        }
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        present(gcVC, animated: true)
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        dismiss(animated: true)
    }
}
