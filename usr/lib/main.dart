import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const JumpGameApp());
}

class JumpGameApp extends StatelessWidget {
  const JumpGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jump & Jump Ultimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Arial', // Fallback font
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

// --- Main Menu Screen ---
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E004F), Color(0xFF580099)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "JUMP & JUMP",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Ultimate Edition",
                style: TextStyle(fontSize: 20, color: Colors.amberAccent),
              ),
              const SizedBox(height: 50),
              _buildMenuButton(context, "PLAY GAME", Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GameScreen()));
              }),
              const SizedBox(height: 20),
              _buildMenuButton(context, "LUCKY WHEEL", Colors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WheelSpinScreen()));
              }),
              const SizedBox(height: 20),
              _buildMenuButton(context, "LOOT BOXES", Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LootBoxScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

// --- Game Engine & Screen ---
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Game Settings
  static const double gravity = 0.5;
  static const double jumpForce = -12.0;
  static const double platformWidth = 80.0;
  static const double platformHeight = 20.0;
  static const double playerSize = 40.0;

  // Game State
  late AnimationController _controller;
  double playerX = 0;
  double playerY = 0;
  double playerVelocityY = 0;
  double scrollOffset = 0;
  int score = 0;
  bool isGameOver = false;
  bool isPaused = false;
  
  // Boss System
  bool bossActive = false;
  double bossX = 0;
  double bossY = -1000; // Off screen initially
  int bossHealth = 3;
  double bossDirection = 2.0;

  List<Rect> platforms = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.repeat();
    _controller.addListener(_gameLoop);
  }

  void _startGame() {
    playerX = 0; // Center (will be set in build based on screen width)
    playerY = 400;
    playerVelocityY = jumpForce;
    scrollOffset = 0;
    score = 0;
    isGameOver = false;
    bossActive = false;
    platforms.clear();
    
    // Initial platforms
    for (int i = 0; i < 10; i++) {
      platforms.add(Rect.fromLTWH(
        _random.nextDouble() * 300,
        600.0 - (i * 100),
        platformWidth,
        platformHeight,
      ));
    }
  }

  void _gameLoop() {
    if (isGameOver || isPaused) return;

    setState(() {
      // Apply Gravity
      playerVelocityY += gravity;
      playerY += playerVelocityY;

      // Screen Wrapping (Pacman style)
      double screenWidth = MediaQuery.of(context).size.width;
      if (playerX < -playerSize) playerX = screenWidth;
      if (playerX > screenWidth) playerX = -playerSize;

      // Camera Follow (Scroll Up)
      if (playerY < 300) {
        double diff = 300 - playerY;
        playerY = 300;
        scrollOffset += diff;
        score += diff.toInt() ~/ 10; // Score based on height

        // Move platforms down
        for (int i = 0; i < platforms.length; i++) {
          platforms[i] = platforms[i].translate(0, diff);
        }
        
        // Move boss down
        if (bossActive) {
          bossY += diff;
        }
      }

      // Platform Generation & Cleanup
      if (platforms.last.top > 0) {
        double newY = platforms.last.top - 100 - _random.nextDouble() * 50;
        platforms.add(Rect.fromLTWH(
          _random.nextDouble() * (screenWidth - platformWidth),
          newY,
          platformWidth,
          platformHeight,
        ));
      }
      platforms.removeWhere((rect) => rect.top > MediaQuery.of(context).size.height);

      // Collision Detection (Only when falling)
      if (playerVelocityY > 0) {
        for (var platform in platforms) {
          if (Rect.fromLTWH(playerX, playerY + playerSize, playerSize, 5)
              .overlaps(platform)) {
            playerVelocityY = jumpForce;
            // Play Sound Effect (Simulated)
            break;
          }
        }
      }

      // Boss Logic (Every 1000 score points roughly)
      if (score > 0 && score % 1000 < 50 && !bossActive && score > 500) {
        bossActive = true;
        bossY = -100;
        bossX = screenWidth / 2;
      }

      if (bossActive) {
        bossX += bossDirection;
        if (bossX <= 0 || bossX >= screenWidth - 60) bossDirection *= -1;
        
        // Boss Collision (Player hits boss)
        Rect bossRect = Rect.fromLTWH(bossX, bossY, 60, 60);
        Rect playerRect = Rect.fromLTWH(playerX, playerY, playerSize, playerSize);
        
        if (playerRect.overlaps(bossRect)) {
          if (playerVelocityY > 0 && playerY < bossY) {
            // Jumped on head
            bossHealth--;
            playerVelocityY = jumpForce;
            if (bossHealth <= 0) {
              bossActive = false;
              score += 500; // Bonus
              bossHealth = 3; // Reset for next
            }
          } else {
            // Hit body - Game Over
            isGameOver = true;
          }
        }
        
        // Despawn boss if passed
        if (bossY > MediaQuery.of(context).size.height) {
          bossActive = false;
        }
      }

      // Game Over Condition (Fall off screen)
      if (playerY > MediaQuery.of(context).size.height) {
        isGameOver = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Initialize player X center on first build
    if (playerX == 0 && score == 0) playerX = screenWidth / 2 - playerSize / 2;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          playerX += details.delta.dx;
        },
        child: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.lightBlueAccent, Colors.white],
                ),
              ),
            ),
            
            // Platforms
            ...platforms.map((rect) => Positioned(
              left: rect.left,
              top: rect.top,
              child: Container(
                width: rect.width,
                height: rect.height,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade800, width: 2),
                ),
              ),
            )),

            // Boss
            if (bossActive)
              Positioned(
                left: bossX,
                top: bossY,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 5)],
                  ),
                  child: const Center(child: Icon(Icons.sentiment_very_dissatisfied, color: Colors.white, size: 40)),
                ),
              ),

            // Player
            Positioned(
              left: playerX,
              top: playerY,
              child: Container(
                width: playerSize,
                height: playerSize,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.face, color: Colors.white),
              ),
            ),

            // HUD
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                "Score: $score",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),

            // Pause Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 30),
                onPressed: () {
                  setState(() {
                    isPaused = !isPaused;
                  });
                },
              ),
            ),

            // Game Over Overlay
            if (isGameOver)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("GAME OVER", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                      Text("Score: $score", style: const TextStyle(color: Colors.white, fontSize: 24)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                        child: const Text("RETRY", style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("MAIN MENU", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Wheel Spin Feature ---
class WheelSpinScreen extends StatefulWidget {
  const WheelSpinScreen({super.key});

  @override
  State<WheelSpinScreen> createState() => _WheelSpinScreenState();
}

class _WheelSpinScreenState extends State<WheelSpinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _finalAngle = 0.0;
  final Random _random = Random();
  String _reward = "Spin to Win!";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.decelerate);
  }

  void _spinWheel() {
    if (_controller.isAnimating) return;
    
    double randomAngle = _random.nextDouble() * 2 * pi + (5 * 2 * pi); // At least 5 full spins
    _finalAngle += randomAngle;
    
    _controller.reset();
    _animation = Tween<double>(begin: 0, end: _finalAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate)
    );
    
    _controller.forward().then((_) {
      setState(() {
        List<String> rewards = ["100 Coins", "No Ads 1h", "Golden Skin", "500 Coins", "Try Again", "Legendary Box"];
        _reward = "You won: ${rewards[_random.nextInt(rewards.length)]}";
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Lucky Wheel"), backgroundColor: Colors.orange),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [Colors.red, Colors.yellow, Colors.blue, Colors.green, Colors.red],
                      ),
                      boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                    ),
                    child: const Center(
                      child: Text("SPIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Icon(Icons.arrow_upward, size: 40, color: Colors.black),
            const SizedBox(height: 40),
            Text(_reward, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _spinWheel,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: const Text("SPIN NOW", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Loot Box Feature ---
class LootBoxScreen extends StatefulWidget {
  const LootBoxScreen({super.key});

  @override
  State<LootBoxScreen> createState() => _LootBoxScreenState();
}

class _LootBoxScreenState extends State<LootBoxScreen> {
  String message = "Select a Box";

  void _openBox(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$type Box Opened!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 60),
            const SizedBox(height: 10),
            Text("You found a random item from the $type tier!"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loot Boxes"), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildLootBoxCard("Wooden Box", Colors.brown, "Free", () => _openBox("Wooden")),
            _buildLootBoxCard("Golden Box", Colors.amber, "100 Coins", () => _openBox("Golden")),
            _buildLootBoxCard("Legendary Box", Colors.purple, "\$0.99", () => _openBox("Legendary")),
          ],
        ),
      ),
    );
  }

  Widget _buildLootBoxCard(String title, Color color, String price, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 5,
      child: ListTile(
        leading: Icon(Icons.inbox, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: const Text("Contains random rewards"),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Text(price, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
