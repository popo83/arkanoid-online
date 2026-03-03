import UIKit
import Foundation
import AVFoundation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // Handle 4in01d://speak?text=Hello
        if url.scheme == "4in01d" && url.host == "speak" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let textItem = components.queryItems?.first(where: { $0.name == "text" }),
               let text = textItem.value {
                speakWithElevenLabs(text: text)
            }
        }
    }
    
    func speakWithElevenLabs(text: String) {
        print("🔊 TTS Request: \(text)")
        
        let apiKey = "sk_787f8c73b2e0abbab6165882ef85dfa3d1826eb0bc8e9d6c"
        let voiceId = "Rachel"
        
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
            
            // Play audio
            DispatchQueue.main.async {
                self?.playAudio(data: data)
            }
        }.resume()
    }
    
    func playAudio(data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            let player = try AVAudioPlayer(data: data)
            player.play()
        } catch {
            print("Audio Error: \(error.localizedDescription)")
        }
    }
}
