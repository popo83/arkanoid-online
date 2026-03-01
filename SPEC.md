# Arkanoid Online - Game Specification

## Overview
- **Name**: Arkanoid Online
- **Genre**: Arcade / Breakout
- **Platform**: iOS
- **Language**: English
- **Graphics**: 2D
- **Multiplayer**: Yes (online)

## Game Mechanics

### Classic Arkanoid
- Paddle at bottom (player controlled)
- Ball bounces and breaks bricks
- Multiple ball types
- Power-ups
- Levels with increasing difficulty

### Multiplayer Mode
- 2-4 players in same arena
- Compete to break most bricks
- Co-op mode also available
- Real-time sync via GameKit or server

## Technical Stack

### Frontend (iOS)
- **SpriteKit** - Native Apple 2D game framework
- **Swift** + UIKit
- **GameKit** - Multiplayer matchmaking

### Backend (Optional)
- **Firebase** or custom server for real-time sync
- Leaderboards
- User accounts

## Features
- [ ] Paddle movement (touch controls)
- [ ] Ball physics
- [ ] Brick grid system
- [ ] Power-ups (multi-ball, wide paddle, laser, etc.)
- [ ] Score system
- [ ] Levels
- [ ] Multiplayer matchmaking
- [ ] Real-time game sync
- [ ] Leaderboards
- [ ] Sound effects
- [ ] Game center integration

## Phase 1 - MVP
1. Basic paddle + ball
2. Brick grid
3. Basic physics
4. Single player mode
5. Score system

## Phase 2 - Multiplayer
1. GameKit integration
2. Matchmaking
3. Real-time sync
4. Multiplayer arena

## Notes
- Start with SpriteKit
- Use GameKit for multiplayer (free, Apple native)
- Deploy to TestFlight when ready
