import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    // Reference to view controller for Game Center
    weak var viewController: GameViewController?
    
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
    var totalPlayTime: TimeInterval = 0
    var gameStartTime: TimeInterval = 0
    var scoreLabel: SKLabelNode!
    var canShoot = true
    var bossSpeed: CGFloat = 250
    var bossHP = 10
    var maxBossHP = 10
    var playerHP = 3
    var maxPlayerHP = 3
    var level = 1
    
    // Pre-generated AI phrases - recycled from previous sessions!
    var usedWelcomeIndices: Set<Int> = []
    var usedDeathIndices: Set<Int> = []
    var usedLevelUpIndices: Set<Int> = []
    var usedGameOverIndices: Set<Int> = []
    
    // Load saved unused phrases from previous session
    func loadSavedPhrases() {
        if let savedWelcome = UserDefaults.standard.array(forKey: "savedWelcomePhrases") as? [String], !savedWelcome.isEmpty {
            welcomePhrases = savedWelcome
            print("📚 Loaded \(savedWelcome.count) saved welcome phrases")
        }
        if let savedDeath = UserDefaults.standard.array(forKey: "savedBossDeathPhrases") as? [String], !savedDeath.isEmpty {
            bossDeathPhrases = savedDeath
            print("📚 Loaded \(savedDeath.count) saved death phrases")
        }
        if let savedLevelUp = UserDefaults.standard.array(forKey: "savedLevelUpPhrases") as? [String], !savedLevelUp.isEmpty {
            levelUpPhrases = savedLevelUp
            print("📚 Loaded \(savedLevelUp.count) saved level up phrases")
        }
        if let savedGameOver = UserDefaults.standard.array(forKey: "savedGameOverPhrases") as? [String], !savedGameOver.isEmpty {
            gameOverPhrases = savedGameOver
            print("📚 Loaded \(savedGameOver.count) saved game over phrases")
        }
    }
    
    // Save unused phrases after game session ends
    func saveUnusedPhrases() {
        // Save welcome phrases not used this session
        var unusedWelcome = welcomePhrases
        for idx in usedWelcomeIndices where idx < welcomePhrases.count {
            // Keep used ones but will regenerate anyway
        }
        UserDefaults.standard.set(welcomePhrases, forKey: "savedWelcomePhrases")
        
        // Save death phrases not used this session
        var unusedDeath = bossDeathPhrases
        UserDefaults.standard.set(unusedDeath, forKey: "savedBossDeathPhrases")
        
        // Save level up phrases not used this session
        UserDefaults.standard.set(levelUpPhrases, forKey: "savedLevelUpPhrases")
        
        // Save game over phrases not used this session
        UserDefaults.standard.set(gameOverPhrases, forKey: "savedGameOverPhrases")
        
        print("💾 Saved unused phrases for next session")
    }
    // Start screen: Insults to make player feel inferior
    var bossDeathPhrases: [String] = [
        "Your pitiful attempt ends here!",
        "Is that all you've got? Pathetic!",
        "I am UNSTOPPABLE! You are NOTHING!",
        "Another worthless challenger... DEFEATED!",
        "Did you really think you could beat ME?!"
    ]
    
    var levelUpPhrases: [String] = [
        "IMPOSSIBLE! But I will DESTROY you next!",
        "You got lucky... BUT NOT FOR LONG!",
        "Fine... Level up! I will CRUSH you harder!",
        "This changes NOTHING! I am ETERNAL!",
        "You think you're good? You are NOTHING!"
    ]
    
    var gameOverPhrases: [String] = [
        "I AM THE BOSS! You are just VERMIN!",
        "Pathetic human! Return when you're WORTHY!",
        "GAME OVER! Your soul belongs to ME!",
        "Insolent fool! You will NEVER defeat me!",
        "Did you enjoy that? It was just WARMUP!"
    ]
    
    var welcomePhrases: [String] = [
        "Kneel before your SUPERIOR! I am ETERNAL!",
        "You dare challenge ME? Your doom APPROACHES!",
        "Another worthless soul seeking DESTRUCTION!",
        "I have crushed a THOUSAND like you!",
        "Your fear... I can SMELL it! Come closer!"
    ]
    var currentWelcomePhrase = "I am waiting..."
    
    // Pre-generated TTS audio data
    var welcomeAudioData: [Data] = []
    var bossDeathAudioData: [Data] = []
    var levelUpAudioData: [Data] = []
    var gameOverAudioData: [Data] = []
    var audioGenerated = 0
    let totalAudioToGenerate = 20
    
    var infiniteHP = false
    var gameState = "menu" // menu, playing, gameover
    var backgroundMusic: AVAudioPlayer?
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
    
    var musicEnabled = true  // Enable music again!
    
    func playBackgroundMusic() {
        guard musicEnabled else { return }
        if backgroundMusic?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: "music", withExtension: "wav") else {
            print("Music file not found!")
            return
        }
        do {
            backgroundMusic = try AVAudioPlayer(contentsOf: url)
            backgroundMusic?.numberOfLoops = -1
            backgroundMusic?.volume = 0.5
            backgroundMusic?.prepareToPlay()
            backgroundMusic?.play()
        } catch {
            print("Errore caricamento musica: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusic?.stop()
        backgroundMusic = nil
    }
    
    func playHitBoss() {
        run(hitBossSound)
        // Boss speaks only 30% of the time when hit!
        if Double.random(in: 0...1) < 0.3 {
            speakBossHit()
        }
    }
    
    func playPlayerHit() {
        run(playerHitSound)
    }
    
    func playLevelUp() {
        run(levelUpSound)
        speakLevelUp()
    }
    
    func playGameOver() {
        run(gameOverSound)
        speakGameOver()
    }
    
    func playLaserHit() {
        run(laserHitSound)
    }
    
    // MARK: - Voice Functions (ElevenLabs TTS)
    func speakBossHit() {
        // Boss no longer speaks when hit - only when dying!
        // Phrases appear when boss dies (end of level)
    }
    
    func speakBossDeath() {
        // Boss death phrase when HP reaches 0
        let availableIndices = Set(0..<bossDeathPhrases.count).subtracting(usedDeathIndices)
        if let idx = availableIndices.randomElement() {
            usedDeathIndices.insert(idx)
            let phrase = bossDeathPhrases[idx]
            speakText(phrase)
        } else {
            let phrase = bossDeathPhrases.randomElement() ?? "You will never defeat me!"
            speakText(phrase)
        }
    }
    
    func speakLevelUp() {
        let availableIndices = Set(0..<levelUpPhrases.count).subtracting(usedLevelUpIndices)
        if let idx = availableIndices.randomElement() {
            usedLevelUpIndices.insert(idx)
            let phrase = levelUpPhrases[idx]
            speakText(phrase)
        } else {
            let phrase = levelUpPhrases.randomElement() ?? "You think you can beat me?!"
            speakText(phrase)
        }
    }
    
    func speakGameOver() {
        let availableIndices = Set(0..<gameOverPhrases.count).subtracting(usedGameOverIndices)
        if let idx = availableIndices.randomElement() {
            usedGameOverIndices.insert(idx)
            let phrase = gameOverPhrases[idx]
            speakText(phrase)
        } else {
            let phrase = gameOverPhrases.randomElement() ?? "I AM THE BOSS! You are NOTHING!"
            speakText(phrase)
        }
    }
    
    // MARK: - AI Chat Function
    func askAI(prompt: String, completion: @escaping (String) -> Void) {
        // Using MiniMax API
        let apiKey = "sk-api-BCuvsVmF1GkihtiPIIyJTMFyrsKOR_KkuweQtpqmW48pmVJdSItEGTwa_wGm4czp0fqt9d_oI0wsKXa-e7JPnDicbEsY88CmDeZ14Gu7UT13lUv2TFjRLRw"
        
        guard let url = URL(string: "https://api.minimax.chat/v1/text/chatcompletion_v2?GroupId=123456789") else {
            completion(getSmartPhrase(for: prompt))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let messages: [[String: Any]] = [
            ["role": "system", "content": "You are a video game boss. Keep responses VERY short (2-6 words). Be menacing."],
            ["role": "user", "content": prompt]
        ]
        
        let body: [String: Any] = [
            "model": "abab6.5s-chat",
            "messages": messages,
            "max_tokens": 50,
            "temperature": 0.7
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(self?.getSmartPhrase(for: prompt) ?? "Got you!")
                return
            }
            
            let cleanResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
            completion(cleanResponse)
        }.resume()
    }
    
    func getSmartPhrase(for prompt: String) -> String {
        // Smart phrase selection based on context
        if prompt.contains("hit you") || prompt.contains("hit") {
            let phrases = [
                "Got you!", "Too slow!", "Nice try!", 
                "Missed me?", "Ouch for you!", "Not this time!",
                "Gotcha!", "Try harder!", "So close!", "Missed!"
            ]
            return phrases.randomElement() ?? "Got you!"
        } else if prompt.contains("leveled up") || prompt.contains("level") {
            let phrases = [
                "Good luck!", "Difficulty rising!", "Here we go!",
                "Warning: stronger!", "Prepare yourself!", "Big mistake!",
                "More challenge!", "Good luck!", "Danger ahead!"
            ]
            return phrases.randomElement() ?? "Level up!"
        } else if prompt.contains("lost") || prompt.contains("game over") {
            let phrases = [
                "Game over!", "You lost!", "Try again!",
                "Better luck!", "Too easy!", "Pathetic!",
                "Owned!", "Destroyed!", "Revenge is mine!"
            ]
            return phrases.randomElement() ?? "Game over!"
        } else if prompt.contains("taunt") || prompt.contains("waiting") {
            let phrases = [
                "I am waiting...", "Think you can win?",
                "Your destiny awaits!", "Challenge accepted?",
                "The boss is ready!", "Prepare to lose!",
                "Do you dare?", "Your end approaches!"
            ]
            return phrases.randomElement() ?? "I am waiting..."
        }
        return "Got you!"
    }
    
    func speakText(_ text: String) {
        // Show text on screen
        showBossMessage(text)
        
        // Play pre-generated audio if available
        playPreGeneratedAudio(for: text)
    }
    
    func playPreGeneratedAudio(for text: String) {
        // Try to find matching pre-generated audio
        var audioData: Data?
        
        if let idx = welcomePhrases.firstIndex(of: text), idx < welcomeAudioData.count {
            audioData = welcomeAudioData[idx]
        } else if let idx = bossDeathPhrases.firstIndex(of: text), idx < bossDeathAudioData.count {
            audioData = bossDeathAudioData[idx]
        } else if let idx = levelUpPhrases.firstIndex(of: text), idx < levelUpAudioData.count {
            audioData = levelUpAudioData[idx]
        } else if let idx = gameOverPhrases.firstIndex(of: text), idx < gameOverAudioData.count {
            audioData = gameOverAudioData[idx]
        }
        
        if let data = audioData {
            playAudio(data: data)
        } else {
            // Fallback to live TTS
            speakWithElevenLabs(text: text)
        }
    }
    
    // Show boss message on screen
    func showBossMessage(_ text: String) {
        // Remove existing message
        childNode(withName: "bossMessage")?.removeFromParent()
        
        let message = SKLabelNode(text: text)
        message.name = "bossMessage"
        message.fontSize = 20
        message.fontColor = .red
        message.position = CGPoint(x: size.width / 2, y: size.height - 130)  // Below boss HP
        message.alpha = 0
        addChild(message)
        
        // Animation: fade in, wait 5 sec, fade out
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 5.0)  // 5 seconds!
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        message.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }
    
    func speakWithElevenLabs(text: String) {
        // TTS disabled - using text instead
        print("🎤 TTS Request (disabled): \(text)")
        
        let apiKey = "sk_f0fb6161f1d1a2426d1e67c4fcff341b3e95d5380db2e3fa"
        let voiceId = "VR6AewTLgFxGq8SpwX53"  // Sam voice (common)
        
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let body: [String: Any] = [
            "text": text,
            "voice_settings": ["stability": 0.5, "similarity_boost": 0.8]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("TTS Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            // Check if response is audio or error
            if let httpResponse = response as? HTTPURLResponse {
                print("TTS Response status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    // Error response - print it
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("TTS API Error: \(json)")
                    }
                    return
                }
                
                // Check content type
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
                print("TTS Content-Type: \(contentType)")
                
                if !contentType.contains("audio") && data.count < 1000 {
                    print("TTS Error: Not audio data, likely error response")
                    return
                }
            }
            
            // Play audio
            DispatchQueue.main.async {
                self?.playAudio(data: data)
            }
        }.resume()
    }
    
    func playAudio(data: Data) {
        print("🔊 Audio data received: \(data.count) bytes")
        
        do {
            // Configure audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            let success = player.play()
            print("🔊 Play started: \(success), duration: \(player.duration)")
        } catch {
            print("🔴 Audio Error: \(error.localizedDescription)")
            
            // Try alternative: save to temp file and play
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("speech.m4a")
            do {
                try data.write(to: tempURL)
                print("🔊 Saved to: \(tempURL)")
            } catch {
                print("🔴 Save error: \(error)")
            }
        }
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
        // Load total play time
        totalPlayTime = UserDefaults.standard.double(forKey: "totalPlayTime")
        
        // Go directly to menu (loading screen disabled for now)
        showMenu()
    }
    
    func showLoadingScreen() {
        gameState = "loading"
        backgroundColor = SKColor.black
        
        // Pre-generate AI phrases during loading
        preGeneratePhrases()
        
        // Animated loading title
        let loadingLabel = SKLabelNode(text: "4IN01D")
        loadingLabel.fontSize = 48
        loadingLabel.fontColor = .green
        loadingLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        loadingLabel.name = "loadingLabel"
        addChild(loadingLabel)
        
        // Pulsing animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        loadingLabel.run(SKAction.repeatForever(pulse))
        
        // Loading dots
        for i in 0..<3 {
            let dot = SKLabelNode(text: ".")
            dot.fontSize = 48
            dot.fontColor = .green
            dot.position = CGPoint(x: size.width / 2 + 70 + CGFloat(i) * 20, y: size.height / 2 + 30)
            dot.name = "dot\(i)"
            dot.alpha = 0.3
            addChild(dot)
            
            // Animate dots
            let delay = Double(i) * 0.3
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ])
            dot.run(SKAction.repeatForever(fade))
        }
        
        // Loading subtitle
        let subLabel = SKLabelNode(text: "AI model loading...")
        subLabel.fontSize = 18
        subLabel.fontColor = .gray
        subLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        subLabel.name = "subLabel"
        addChild(subLabel)
        
        // Start AI phrase generation + TTS (5 seconds)
        preGeneratePhrases()
        
        // Backup: after 5 seconds, go to menu anyway
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            if self?.gameState == "loading" {
                self?.goToMenuFromLoading()
            }
        }
    }
    
    // Pre-generated AI phrases counter
    var phrasesGenerated = 0
    let totalPhrases = 20  // 5 phrases x 4 categories
    
    // Pre-generate AI phrases for the game session
    func preGeneratePhrases() {
        print("🤖 AI: Pre-generating + recycling phrases...")
        phrasesGenerated = 0
        
        // First load any saved phrases from previous session
        loadSavedPhrases()
        
        // Generate 5 aggressive welcome/insult phrases
        for i in 1...5 {
            let context = "Sei un CATTIVO boss arcade. Crea insultiangatISSIMI e MINACCE in ITALIANO come: 'ti schiaccio come una formica', 'sei inutile', 'essere inferiore', 'piccolo stupido umano', 'non vali nulla', 'sei patetico'. Fai sentire il giocatore INFERIORE. Usa MAIUSCOLE. 4-10 parole. Creativo #\(i)."
            askAI(prompt: context) { [weak self] response in
                if !response.isEmpty && response.count > 10 {
                    self?.welcomePhrases[i-1] = response
                }
                self?.phrasesGenerated += 1
                self?.checkPhrasesReady()
            }
        }
        
        // Generate 5 boss death phrases (at end of level)
        for i in 1...5 {
            let context = "Il boss sta MORENDO! Crea insulti ULTIMI e MINACCE in ITALIANO come: 'ti schiaccio come una formica', 'non vali nulla', 'essere inferiore'. Il boss DEVE insultare e minacciare. Usa MAIUSCOLE. 4-10 parole. Creativo #\(i)."
            askAI(prompt: context) { [weak self] response in
                if !response.isEmpty && response.count > 10 {
                    self?.bossDeathPhrases[i-1] = response
                }
                self?.phrasesGenerated += 1
                self?.checkPhrasesReady()
            }
        }
        
        // Generate 5 level up phrases
        for i in 1...5 {
            let context = "Il giocatore ha superato il livello! Crea insulti MINACCIOSI in ITALIANO come: 'ti schiaccio come una formica', 'sei patetico', 'sei inutile'. Il boss DEVE insultare e promettere distruzione. Usa MAIUSCOLE. 4-10 parole. Creativo #\(i)."
            askAI(prompt: context) { [weak self] response in
                if !response.isEmpty && response.count > 10 {
                    self?.levelUpPhrases[i-1] = response
                }
                self?.phrasesGenerated += 1
                self?.checkPhrasesReady()
            }
        }
        
        // Generate 5 game over phrases
        for i in 1...5 {
            let context = "Il giocatore ha perso completamente! Crea una FRASE DI VITTORIA MOCcante e MALVAGIA in ITALIANO. Fai sembrare il boss superiore e crudele. Usa MAIUSCOLE. 4-10 parole. Creativo #\(i)."
            askAI(prompt: context) { [weak self] response in
                if !response.isEmpty && response.count > 10 {
                    self?.gameOverPhrases[i-1] = response
                }
                self?.phrasesGenerated += 1
                self?.checkPhrasesReady()
            }
        }
    }
    
    func checkPhrasesReady() {
        print("🤖 AI: \(phrasesGenerated)/\(totalPhrases) phrases ready")
        
        if phrasesGenerated >= totalPhrases {
            // All phrases ready - start generating TTS audio
            generateAllTTSAudio()
        }
    }
    
    // Generate TTS audio for all phrases during loading
    func generateAllTTSAudio() {
        print("🎤 Generating TTS audio for all phrases...")
        audioGenerated = 0
        
        // Generate for welcome phrases
        for phrase in welcomePhrases {
            generateTTSAudio(text: phrase) { [weak self] data in
                if let data = data {
                    self?.welcomeAudioData.append(data)
                }
                self?.audioGenerated += 1
                self?.checkAudioReady()
            }
        }
        
        // Generate for boss death phrases
        for phrase in bossDeathPhrases {
            generateTTSAudio(text: phrase) { [weak self] data in
                if let data = data {
                    self?.bossDeathAudioData.append(data)
                }
                self?.audioGenerated += 1
                self?.checkAudioReady()
            }
        }
        
        // Generate for level up phrases
        for phrase in levelUpPhrases {
            generateTTSAudio(text: phrase) { [weak self] data in
                if let data = data {
                    self?.levelUpAudioData.append(data)
                }
                self?.audioGenerated += 1
                self?.checkAudioReady()
            }
        }
        
        // Generate for game over phrases
        for phrase in gameOverPhrases {
            generateTTSAudio(text: phrase) { [weak self] data in
                if let data = data {
                    self?.gameOverAudioData.append(data)
                }
                self?.audioGenerated += 1
                self?.checkAudioReady()
            }
        }
    }
    
    func checkAudioReady() {
        print("🎤 TTS: \(audioGenerated)/\(totalAudioToGenerate) audio generated")
        
        if audioGenerated >= totalAudioToGenerate {
            // All audio ready - go to menu
            DispatchQueue.main.async { [weak self] in
                self?.goToMenuFromLoading()
            }
        }
    }
    
    func generateTTSAudio(text: String, completion: @escaping (Data?) -> Void) {
        let apiKey = "sk_f0fb6161f1d1a2426d1e67c4fcff341b3e95d5380db2e3fa"
        let voiceId = "pNInz6obpgDQGcFmaJgB"
        
        guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let body: [String: Any] = [
            "text": text,
            "voice_settings": ["stability": 0.5, "similarity_boost": 0.8]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
    
    func goToMenuFromLoading() {
        removeAllChildren()
        saveUnusedPhrases()  // Save for next session
        // Reset used indices for new session
        usedWelcomeIndices.removeAll()
        usedDeathIndices.removeAll()
        usedLevelUpIndices.removeAll()
        usedGameOverIndices.removeAll()
        showMenu()
    }
    
    func showMenu() {
        gameState = "menu"
        backgroundColor = SKColor.black
        // Save play time
        if gameStartTime > 0 {
            let played = Date().timeIntervalSince1970 - gameStartTime
            totalPlayTime += played
            UserDefaults.standard.set(totalPlayTime, forKey: "totalPlayTime")
            gameStartTime = 0
        }
        removeAllChildren()
        
        // Start background music with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.playBackgroundMusic()
        }
        
        // Title
        let titleLabel = SKLabelNode(text: "4IN01D")
        titleLabel.fontSize = 48
        titleLabel.fontColor = .cyan
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        addChild(titleLabel)
        
        let subtitleLabel = SKLabelNode(text: "Challenge the AI")
        subtitleLabel.fontSize = 24
        subtitleLabel.fontColor = .green
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height - 160)
        addChild(subtitleLabel)
        
        // AI Welcome Message (from pool, tracking usage)
        let availableWelcome = Set(0..<welcomePhrases.count).subtracting(usedWelcomeIndices)
        var welcomeText = "I am waiting..."
        if let idx = availableWelcome.randomElement() {
            usedWelcomeIndices.insert(idx)
            welcomeText = welcomePhrases[idx]
        }
        
        let aiMessage = SKLabelNode(text: welcomeText)
        aiMessage.fontSize = 16
        aiMessage.fontColor = .gray
        aiMessage.position = CGPoint(x: size.width / 2, y: size.height - 190)
        aiMessage.name = "aiWelcome"
        addChild(aiMessage)
        
        // High Score
        let hsLabel = SKLabelNode(text: "HIGH SCORE: \(highScore)")
        hsLabel.fontSize = 22
        hsLabel.fontColor = .yellow
        hsLabel.position = CGPoint(x: size.width / 2, y: size.height - 220)
        addChild(hsLabel)
        
        // Play time
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        let timeText = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        let timeLabel = SKLabelNode(text: "Play Time: \(timeText)")
        timeLabel.fontSize = 16
        timeLabel.fontColor = .gray
        timeLabel.position = CGPoint(x: size.width / 2, y: size.height - 250)
        addChild(timeLabel)
        
        // Start Button
        // AI START Challenge - replace TAP TO START
        let startPhrase = welcomePhrases.randomElement() ?? "NON OSARE SFIDARMI!"
        let startButton = SKLabelNode(text: startPhrase)
        startButton.name = "startButton"
        startButton.fontSize = 24
        startButton.fontColor = .red
        startButton.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        addChild(startButton)
        
        // Music toggle button
        let musicText = musicEnabled ? "🔊 MUSIC ON" : "🔇 MUSIC OFF"
        let musicButton = SKLabelNode(text: musicText)
        musicButton.name = "musicButton"
        musicButton.fontSize = 16
        musicButton.fontColor = .gray
        musicButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        addChild(musicButton)
        
        // Leaderboard button
        let leaderboardButton = SKLabelNode(text: "🏆 LEADERBOARD")
        leaderboardButton.name = "leaderboardButton"
        leaderboardButton.fontSize = 18
        leaderboardButton.fontColor = .yellow
        leaderboardButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 50)
        addChild(leaderboardButton)
        
        // DEBUG: Infinite HP Button (bottom center)
        let debugButton = SKLabelNode(text: "DEBUG: INFINITE HP")
        debugButton.name = "debugInfiniteHP"
        debugButton.fontSize = 14
        debugButton.fontColor = .red
        debugButton.position = CGPoint(x: size.width / 2, y: 30)
        addChild(debugButton)
        
        // Instructions
        let instrLabel = SKLabelNode(text: "Developed by J4K08")
        instrLabel.fontSize = 14
        instrLabel.fontColor = .gray
        instrLabel.position = CGPoint(x: size.width / 2, y: 55)
        addChild(instrLabel)
    }
    
    // MARK: - Setup
    
    func setupGame() {
        gameState = "playing"
        // Start play timer
        gameStartTime = Date().timeIntervalSince1970
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
        
        // Enable color blending
        paddle.colorBlendFactor = 1.0
        
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
            
            // Check music toggle button
            if let musicBtn = childNode(withName: "musicButton") as? SKLabelNode {
                let musicFrame = CGRect(
                    x: musicBtn.position.x - 60,
                    y: musicBtn.position.y - 15,
                    width: 120,
                    height: 30
                )
                if musicFrame.contains(touchLocation) {
                    musicEnabled = !musicEnabled
                    if musicEnabled {
                        playBackgroundMusic()
                        musicBtn.text = "🔊 MUSIC ON"
                    } else {
                        backgroundMusic?.stop()
                        musicBtn.text = "🔇 MUSIC OFF"
                    }
                    return
                }
            }
            
            // Check leaderboard button
            if let lbBtn = childNode(withName: "leaderboardButton") as? SKLabelNode {
                let lbFrame = CGRect(
                    x: lbBtn.position.x - 80,
                    y: lbBtn.position.y - 15,
                    width: 160,
                    height: 30
                )
                if lbFrame.contains(touchLocation) {
                    viewController?.showLeaderboard()
                    return
                }
            }
            
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
        
        // If game over (including credits), tap to restart
        if gameState == "gameover" {
            level = 1
            score = 0
            playerHP = 3
            showMenu()
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
        
        // Create a circular texture for particles
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        let image = renderer.image { ctx in
            UIColor.orange.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        emitter.particleTexture = SKTexture(image: image)
        
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 1.0
        emitter.particleLifetimeRange = 0.5
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 100
        emitter.particleAlpha = 1.0
        emitter.particleAlphaRange = 0.3
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = .orange
        emitter.particleColorBlendFactor = 1.0
        emitter.emissionAngleRange = CGFloat.pi * 2
        emitter.position = position
        emitter.zPosition = 100
        addChild(emitter)
        
        let wait = SKAction.wait(forDuration: 2.0)
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
        
        // Auto shoot lasers - FASTER when low HP!
        let fireInterval: TimeInterval
        switch playerHP {
        case 3: fireInterval = 0.3  // Normal
        case 2: fireInterval = 0.2  // Faster
        default: fireInterval = 0.1  // Maximum speed!
        }
        
        if currentTime - lastPlayerShotTime > fireInterval {
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
                    speakBossDeath()  // Boss insult before dying!
                    winGame()
                    return
                }
                continue
            }
            
            // Check collision with enemy lasers - LASER VS LASER!
            for j in stride(from: enemyLasers.count - 1, through: 0, by: -1) {
                if j < enemyLasers.count && laser.frame.intersects(enemyLasers[j].frame) {
                    // Both lasers destroyed!
                    let collisionPoint = CGPoint(
                        x: (laser.position.x + enemyLasers[j].position.x) / 2,
                        y: (laser.position.y + enemyLasers[j].position.y) / 2
                    )
                    createExplosion(at: collisionPoint)
                    
                    enemyLasers[j].removeFromParent()
                    enemyLasers.remove(at: j)
                    
                    laser.removeFromParent()
                    lasers.remove(at: i)
                    break  // Stop checking this laser
                }
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
        // Submit score to Game Center
        if !infiniteHP {
            viewController?.submitScoreToLeaderboard(score)
        }
        
        // Check if level 10 completed - GAME WON!
        if level >= 10 {
            showCredits()
            return
        }
        
        isBallActive = false
        isGameOver = true
        
        playLevelUp()
        
        let levelUpLabel = SKLabelNode(text: "LEVEL \(level) COMPLETE!")
        levelUpLabel.fontSize = 36
        levelUpLabel.fontColor = .green
        levelUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        addChild(levelUpLabel)
        
        // Sci-fi warning messages per level
        let sciFiWarnings = [
            "⚠️ SYSTEM: Boss upgraded",
            "🔧 AI: Neural network expanded",
            "🧠 WARNING: Boss adapting",
            "💀 DANGER: Enemy evolving",
            "⚡ POWER: Boss speed up",
            "🤖 ALERT: AI learning fast",
            "🔥 HAZARD: Maximum difficulty",
            "🛡️ CRITICAL: Defense mode",
            "☠️ WARNING: Boss rage mode",
            "👑 FINAL FORM: Good luck!"
        ]
        
        let nextLvl = level + 1
        let warningIndex = min(nextLvl - 1, sciFiWarnings.count - 1)
        let warning = sciFiWarnings[warningIndex]
        
        let warningLabel = SKLabelNode(text: warning)
        warningLabel.fontSize = 22
        warningLabel.fontColor = .yellow
        warningLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 55)
        addChild(warningLabel)
        
        // Real AI stats for next level
        let aiAccuracy = 0.90 + Double(nextLvl) * 0.01
        let mistakeChance = max(0.30 - (Double(nextLvl) - 1) * 0.05, 0.02)
        let bossSpeedLvl = 250 + (nextLvl - 1) * 80
        let bossHPLvl = min(10 + (nextLvl - 1) * 5, 50)
        
        let aiStatsLabel = SKLabelNode(text: "ACC:\(String(format: "%.0f", aiAccuracy*100))% ERR:\(String(format: "%.0f", mistakeChance*100))% | SPD:\(bossSpeedLvl)")
        aiStatsLabel.fontSize = 18
        aiStatsLabel.fontColor = .cyan
        aiStatsLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 35)
        addChild(aiStatsLabel)
        
        // HP info
        let hpText = "Boss HP: \(bossHPLvl)"
        let nextLabel = SKLabelNode(text: "Tap for \(hpText)")
        nextLabel.fontSize = 18
        nextLabel.fontColor = .white
        nextLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        nextLabel.name = "nextLevel"
        addChild(nextLabel)
    }
    
    func showCredits() {
        isBallActive = false
        isGameOver = true
        gameState = "gameover"
        
        // Save high score
        if score > highScore && !infiniteHP {
            highScore = score
            UserDefaults.standard.set(highScore, forKey: "highScore")
        }
        
        playLevelUp()
        
        // Clear screen
        removeAllChildren()
        
        // Dark background
        backgroundColor = SKColor.black
        
        // Title
        let titleLabel = SKLabelNode(text: "🏆 YOU WIN! 🏆")
        titleLabel.fontSize = 40
        titleLabel.fontColor = .yellow
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        addChild(titleLabel)
        
        // Credits
        let credits = [
            "",
            "4IN01D",
            "",
            "A Game by J4K08",
            "",
            "Built with Swift",
            "SpriteKit Engine",
            "",
            "Music: 8-bit Retro",
            "",
            "Thanks for Playing!",
            "",
            "Tap to Restart"
        ]
        
        var yPos = size.height * 0.6
        for credit in credits {
            let label = SKLabelNode(text: credit)
            label.fontSize = (credit.isEmpty || credit == "Tap to Restart") ? 16 : 20
            label.fontColor = credit.contains("🏆") ? .yellow : .white
            label.position = CGPoint(x: size.width / 2, y: yPos)
            addChild(label)
            yPos -= 35
        }
    }
    
    func gameOver() {
        isBallActive = false
        isGameOver = true
        gameState = "gameover"
        
        // Submit score to Game Center
        if !infiniteHP {
            viewController?.submitScoreToLeaderboard(score)
        }
        
        // Stop background music
        stopBackgroundMusic()
        
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

