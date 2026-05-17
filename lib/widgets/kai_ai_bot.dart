import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';

/// Kai AI Floating Assistant Widget
class KaiAiBot extends StatefulWidget {
  const KaiAiBot({Key? key}) : super(key: key);

  @override
  State<KaiAiBot> createState() => _KaiAiBotState();
}

class _KaiAiBotState extends State<KaiAiBot> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _breathingController;
  late AnimationController _sparkleController;
  late AnimationController _hoverController;
  late AnimationController _chatWindowController;

  // Animations
  late Animation<double> _breathingOffset;
  late Animation<double> _glowRadius;
  late Animation<double> _hoverScale;
  late Animation<double> _chatScale;
  late Animation<double> _chatOpacity;

  bool _isHovered = false;
  bool _isOpen = false;
  bool _isTyping = false;
  
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _sessionId = "everbloom_user_${DateTime.now().millisecondsSinceEpoch}";
  
  // List of particle flowers / sparkles
  final List<_PetalParticle> _particles = [];

  // Suggestion chips
  final List<String> _suggestions = [
    "Tell me about EverBloom 🌸",
    "How to place an order? 🛍️",
    "Where is the florist map? 🗺️",
    "Just want to chat! 😊",
  ];

  @override
  void initState() {
    super.initState();

    // 1. Slow up-down breathing motion
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _breathingOffset = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _glowRadius = Tween<double>(begin: 12.0, end: 24.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // 2. Hover bounce/scale
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    // 3. Sparkle / Petal particles animation
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    // Initialize 6 particles
    final random = math.Random();
    for (int i = 0; i < 6; i++) {
      _particles.add(_PetalParticle(
        angle: random.nextDouble() * 2 * math.pi,
        radius: 35.0 + random.nextDouble() * 25.0,
        speed: 0.4 + random.nextDouble() * 0.6,
        size: 4.0 + random.nextDouble() * 6.0,
        color: i % 2 == 0 ? const Color(0xFFFFC6FF) : const Color(0xFFCAFFBF),
      ));
    }

    // 4. Chat window scale + fade transition
    _chatWindowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _chatScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _chatWindowController, curve: Curves.easeOutBack),
    );
    _chatOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chatWindowController, curve: Curves.easeIn),
    );

    // Initial greeting
    _messages.add({
      "role": "assistant",
      "content": "Hello, sweet flower! 🌸 I am Kai, your floating garden spirit. How can I brighten your day in EverBloom today? 🍃✨",
      "time": DateTime.now(),
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _sparkleController.dispose();
    _hoverController.dispose();
    _chatWindowController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================================
  // ENVIRONMENT-AWARE API CONFIGURATION & RESOLUTION
  // =========================================================================
  
  // 🌟 PRODUCTION HOSTING URL
  // Replace this placeholder with your actual hosted API production URL once deployed.
  // For Render free tier: 'https://everblooms-3.onrender.com'
  // For Railway free/low-cost tier: 'https://your-app-name.up.railway.app'
  static const String _prodBackendUrl = 'https://everblooms-3.onrender.com';

  // For Android Physical Devices in local development:
  // Set this to 'http://localhost:8000' and run: `adb reverse tcp:8000 tcp:8000` on your PC.
  static const String _localDevIp = 'http://localhost:8000';

  // Automatic Backend URL Resolution
  String _getBackendUrl() {
    // 🌟 SENIOR DEV DESIGN DECISION:
    // To ensure the chatbot works flawlessly even when you unplug your laptop cable
    // or run the app on the go, we default to the cloud backend (Render).
    // Set this to true ONLY if you are actively editing the local Python backend on your PC.
    const bool useLocalDevelopmentServer = false;

    if (useLocalDevelopmentServer && !kReleaseMode) {
      if (kIsWeb) {
        return 'http://localhost:8000';
      }
      try {
        if (Platform.isAndroid) {
          // Emulators default to 10.0.2.2. If on physical device with adb reverse, use localhost.
          return 'http://10.0.2.2:8000';
        }
        return 'http://localhost:8000';
      } catch (e) {
        return 'http://localhost:8000';
      }
    }

    // Default production cloud backend
    return _prodBackendUrl;
  }

  // =========================================================================
  // EXPONENTIAL BACKOFF RETRY CONTROLLER
  // =========================================================================
  
  /// Performs an HTTP POST request with built-in retries and exponential backoff.
  /// Retries on server errors (5xx, e.g. Render app sleeping or 503 Tunnel Errors) and network timeouts.
  Future<http.Response> _postWithRetry(
    String url, {
    required Map<String, String> headers,
    required String body,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? 
        (url.contains("onrender.com") ? const Duration(seconds: 75) : const Duration(seconds: 15));
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        debugPrint("Kai AI API Attempt $attempt to $url...");
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        ).timeout(effectiveTimeout);

        // Return immediately if successful (200)
        if (response.statusCode == 200) {
          return response;
        }

        // Retry on server errors (5xx), HTTP request timeouts (408), or temporary gateways (503 / 504)
        if (response.statusCode >= 500 || response.statusCode == 408 || response.statusCode == 503) {
          debugPrint("API Server Error (${response.statusCode}) on attempt $attempt");
          if (attempt >= maxAttempts) {
            return response; // Out of attempts, return the final error response
          }
        } else {
          // Client errors (400, 401, 403, 404) mean the request itself is bad, so retrying won't help
          return response;
        }
      } catch (e) {
        debugPrint("API network error on attempt $attempt: $e");
        if (attempt >= maxAttempts) {
          rethrow; // Final attempt failed with a network exception, rethrow
        }
      }

      // Calculate exponential backoff delay: initialDelay * 2^(attempt - 1)
      final backoffSeconds = initialDelay.inSeconds * math.pow(2, attempt - 1).toInt();
      final backoffDuration = Duration(seconds: backoffSeconds);
      debugPrint("Waiting ${backoffDuration.inSeconds}s before retry attempt ${attempt + 1}...");
      await Future.delayed(backoffDuration);
    }
  }

  // Toggle chat window open/close
  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _chatWindowController.forward();
      } else {
        _chatWindowController.reverse();
      }
    });
  }

  // Call the Python backend API
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = {
      "role": "user",
      "content": text,
      "time": DateTime.now(),
    };

    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      _inputController.clear();
    });

    _scrollToBottom();

    try {
      final backendUrl = "${_getBackendUrl()}/api/chat";
      debugPrint("Kai AI calling API: $backendUrl");
      
      http.Response response;
      try {
        final isRender = backendUrl.contains("onrender.com");
        response = await _postWithRetry(
          backendUrl,
          headers: {
            "Content-Type": "application/json",
            "Bypass-Tunnel-Reminder": "true", // Bypass temporary tunnel blocks
          },
          body: jsonEncode({
            "message": text,
            "session_id": _sessionId,
          }),
          maxAttempts: isRender ? 1 : 2,
        );
      } catch (localError) {
        // If we are in debug mode and a local request failed (unreachable/timed out),
        // let's try calling our hosted cloud server as an automatic fallback!
        // This makes physical Android devices work in debug mode instantly out of the box.
        if (!kReleaseMode && (backendUrl.contains("10.0.2.2") || backendUrl.contains("localhost") || backendUrl.contains("127.0.0.1"))) {
          debugPrint("Local server unreachable ($localError). Automatically falling back to production cloud URL...");
          final fallbackCloudUrl = "$_prodBackendUrl/api/chat";
          response = await _postWithRetry(
            fallbackCloudUrl,
            headers: {
              "Content-Type": "application/json",
              "Bypass-Tunnel-Reminder": "true",
            },
            body: jsonEncode({
              "message": text,
              "session_id": _sessionId,
            }),
            maxAttempts: 2, // Try twice on the cloud server
          );
        } else {
          // If already in production release mode or cloud failed, just bubble up the error
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data["reply"] ?? "A lovely breeze swept my thoughts away. Let's try again! 🌸";

        setState(() {
          _messages.add({
            "role": "assistant",
            "content": reply,
            "time": DateTime.now(),
          });
        });
      } else {
        debugPrint("API Error after retries: ${response.statusCode} - ${response.body}");
        _showOfflineFallback();
      }
    } catch (e) {
      debugPrint("API Connection Exception after retries: $e");
      _showOfflineFallback();
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  // Fallback responses if Python backend is offline
  void _showOfflineFallback() {
    String fallbackReply = "Oh dear! It seems my garden connection is a bit drafty right now. 🌬️ "
        "But don't worry, sweet bloom! EverBloom is a magical marketplace connecting you with local florists. "
        "You can explore gorgeous Bouquets on the Home screen or look around on the florist Map. "
        "I will be fully ready to chat as soon as my garden server is refreshed! 🌸✨";
        
    setState(() {
      _messages.add({
        "role": "assistant",
        "content": fallbackReply,
        "time": DateTime.now(),
      });
    });
  }

  // Clear Chat History API
  Future<void> _clearChatHistory() async {
    setState(() {
      _messages.clear();
      _messages.add({
        "role": "assistant",
        "content": "Garden cleared and refreshed! 🍃 What new ideas shall we grow together?",
        "time": DateTime.now(),
      });
    });

    try {
      final backendUrl = "${_getBackendUrl()}/api/chat/clear";
      
      try {
        await _postWithRetry(
          backendUrl,
          headers: {
            "Content-Type": "application/json",
            "Bypass-Tunnel-Reminder": "true",
          },
          body: jsonEncode({"session_id": _sessionId}),
          maxAttempts: 1, // Only 1 attempt is needed to clear chat logs locally
        );
      } catch (localError) {
        // Fallback for clear history in debug mode
        if (!kReleaseMode && (backendUrl.contains("10.0.2.2") || backendUrl.contains("localhost") || backendUrl.contains("127.0.0.1"))) {
          debugPrint("Local server unreachable for history clear. Falling back to cloud...");
          final fallbackCloudUrl = "$_prodBackendUrl/api/chat/clear";
          await _postWithRetry(
            fallbackCloudUrl,
            headers: {
              "Content-Type": "application/json",
              "Bypass-Tunnel-Reminder": "true",
            },
            body: jsonEncode({"session_id": _sessionId}),
            maxAttempts: 1,
          );
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint("Error clearing backend history: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // 1. Chat Window Panel
        if (_isOpen || _chatWindowController.isAnimating)
          Positioned(
            right: 0,
            bottom: 80,
            child: ScaleTransition(
              scale: _chatScale,
              alignment: Alignment.bottomRight,
              child: FadeTransition(
                opacity: _chatOpacity,
                child: _buildChatWindow(theme, size),
              ),
            ),
          ),

        // 2. Floating Circular Button & Sparkles
        if (!_isOpen)
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_breathingOffset.value),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Sparkles / Flower Petals particle system around button
                    ..._particles.map((particle) {
                      final progress = _sparkleController.value;
                      final currentAngle = particle.angle + (progress * 2 * math.pi * particle.speed);
                      final dx = math.cos(currentAngle) * particle.radius;
                      final dy = math.sin(currentAngle) * particle.radius * 0.8;
                      final scale = 0.5 + (0.5 * math.sin(progress * 2 * math.pi + particle.angle));
                      
                      return Positioned(
                        left: 32 + dx,
                        top: 32 + dy,
                        child: Opacity(
                          opacity: 0.2 + 0.6 * (1.0 - progress),
                          child: Transform.scale(
                            scale: scale,
                            child: Icon(
                              LucideIcons.sparkles,
                              color: particle.color,
                              size: particle.size,
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // Floating Button
                    MouseRegion(
                      onEnter: (_) {
                        setState(() => _isHovered = true);
                        _hoverController.forward();
                      },
                      onExit: (_) {
                        setState(() => _isHovered = false);
                        _hoverController.reverse();
                      },
                      child: GestureDetector(
                        onTap: _toggleChat,
                        child: ScaleTransition(
                          scale: _hoverScale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFB7B2), // Soft pink
                                  Color(0xFFFFDAC1), // Soft peach
                                  Color(0xFFE2F0CB), // Soft green
                                  Color(0xFFB5EAD7), // Soft mint
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB5E8).withOpacity(_isHovered ? 0.6 : 0.35),
                                  blurRadius: _isHovered ? 28.0 : _glowRadius.value,
                                  spreadRadius: _isHovered ? 6.0 : 2.0,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: -1,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: _KaiAvatarWidget(size: 42),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // Building the Chat Window Widget
  Widget _buildChatWindow(ThemeData theme, Size size) {
    // Restrict width on mobile vs desktop
    final double chatWidth = math.min(360.0, size.width - 32);
    final double chatHeight = math.min(520.0, size.height - 220);

    return Container(
      width: chatWidth,
      height: chatHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFFFB5E8).withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Header of Chat
                _buildHeader(theme),

                // Messages area
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      
                      final msg = _messages[index];
                      final isUser = msg["role"] == "user";
                      return _buildMessageBubble(msg["content"], isUser, theme);
                    },
                  ),
                ),

                // Suggestions chips (only visible if typing is not active and input is empty)
                if (_messages.length <= 1 && !_isTyping) _buildSuggestions(),

                // Input box
                _buildInputBar(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom Header Widget
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFC6FF).withOpacity(0.25), // Pastel pink tint
            const Color(0xFFCAFFBF).withOpacity(0.15), // Pastel green tint
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.pink.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar with online status glow
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB7B2), Color(0xFFB5EAD7)],
                  ),
                ),
                child: const Center(
                  child: _KaiAvatarWidget(size: 28),
                ),
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7FE78C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7FE78C).withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Bot Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Kai AI",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: const Color(0xFF6B4E71),
                  ).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
                ),
                Text(
                  "Your garden companion",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFAA8C9E),
                  ).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
                ),
              ],
            ),
          ),
          // Clear History Button
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFFAA8C9E)),
            tooltip: "Clear history",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Clear Garden Chat?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  content: const Text("Would you like to clear our conversation history and start fresh? 🌸"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Keep"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearChatHistory();
                      },
                      child: const Text("Clear", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          // Close button
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF6B4E71)),
            onPressed: _toggleChat,
          ),
        ],
      ),
    );
  }

  // Message Bubble builder
  Widget _buildMessageBubble(String content, bool isUser, ThemeData theme) {
    // Custom organic shapes for message bubbles
    final bubbleRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          );

    final bubbleBg = isUser
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF85A1), // Warm custom pink
              Color(0xFFFFB5A7), // Warm peach pink
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF3E7F9).withOpacity(0.9), // Super soft lavender
              const Color(0xFFE2F5E2).withOpacity(0.9), // Super soft floral green
            ],
          );

    final textStyle = isUser
        ? GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ).copyWith(fontFamilyFallback: const ['NotoColorEmoji'])
        : GoogleFonts.inter(
            color: const Color(0xFF4A3E4D),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ).copyWith(fontFamilyFallback: const ['NotoColorEmoji']);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        decoration: BoxDecoration(
          borderRadius: bubbleRadius,
          gradient: bubbleBg,
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? const Color(0xFFFF85A1).withOpacity(0.2)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Text(content, style: textStyle),
      ),
    );
  }

  // Suggestion chips row
  Widget _buildSuggestions() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final text = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              backgroundColor: Colors.white.withOpacity(0.85),
              elevation: 0,
              pressElevation: 2,
              side: BorderSide(color: const Color(0xFFFFC6FF).withOpacity(0.4), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              label: Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: const Color(0xFF6B4E71),
                  fontWeight: FontWeight.w500,
                ).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
              ),
              onPressed: () => _sendMessage(text),
            ),
          );
        },
      ),
    );
  }

  // Input Bar widget
  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        border: Border(
          top: BorderSide(
            color: Colors.pink.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFFFD6E8).withOpacity(0.6),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: TextField(
                  controller: _inputController,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF333333)).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Ask Kai about flowers...",
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13).copyWith(fontFamilyFallback: const ['NotoColorEmoji']),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          GestureDetector(
            onTap: () => _sendMessage(_inputController.text),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF85A1),
                    Color(0xFFFFB5E8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF85A1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(
                LucideIcons.send,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Jumping dots typing indicator
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          color: const Color(0xFFF3E7F9).withOpacity(0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBouncingDot(0),
            const SizedBox(width: 4),
            _buildBouncingDot(1),
            const SizedBox(width: 4),
            _buildBouncingDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildBouncingDot(int delayIndex) {
    return _BouncingDot(delay: Duration(milliseconds: delayIndex * 150));
  }
}

// Bouncing dot helper for typing indicator
class _BouncingDot extends StatefulWidget {
  final Duration delay;
  const _BouncingDot({required this.delay, Key? key}) : super(key: key);

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF6B4E71),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Custom Painter for Kai AI - Flower Spirit Avatar
class _KaiAvatarWidget extends StatelessWidget {
  final double size;
  const _KaiAvatarWidget({required this.size, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KaiAvatarPainter(),
      ),
    );
  }
}

class _KaiAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 4;

    final Paint petalPaint = Paint()
      ..style = PaintingStyle.fill;

    // Draw 8 flower petals
    final int numPetals = 8;
    for (int i = 0; i < numPetals; i++) {
      final double angle = (i * 2 * math.pi) / numPetals;
      final double petalX = cx + math.cos(angle) * (radius * 1.25);
      final double petalY = cy + math.sin(angle) * (radius * 1.25);

      // Gradient for each petal for deep premium aesthetic
      petalPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFB5E8).withValues(alpha: 0.95), // Pink
          const Color(0xFFFFDAC1).withValues(alpha: 0.85), // Warm peach
        ],
      ).createShader(Rect.fromCircle(center: Offset(petalX, petalY), radius: radius * 0.8));

      canvas.drawCircle(Offset(petalX, petalY), radius * 0.72, petalPaint);
    }

    // Draw central flower disc (face background)
    final Paint faceBgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9E6), // Creamy white
          Color(0xFFFFF0C2), // Warm buttercup yellow
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.1))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), radius * 1.05, faceBgPaint);
    
    // Face border/shadow
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFF9E4B7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(cx, cy), radius * 1.05, borderPaint);

    // Draw cute happy eyes ^ ^
    final Paint eyePaint = Paint()
      ..color = const Color(0xFF7B526F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Left eye arc
    final Path leftEyePath = Path()
      ..moveTo(cx - radius * 0.55, cy - radius * 0.05)
      ..quadraticBezierTo(
        cx - radius * 0.35, cy - radius * 0.28, // Peak
        cx - radius * 0.15, cy - radius * 0.05,
      );
    canvas.drawPath(leftEyePath, eyePaint);

    // Right eye arc
    final Path rightEyePath = Path()
      ..moveTo(cx + radius * 0.15, cy - radius * 0.05)
      ..quadraticBezierTo(
        cx + radius * 0.35, cy - radius * 0.28, // Peak
        cx + radius * 0.55, cy - radius * 0.05,
      );
    canvas.drawPath(rightEyePath, eyePaint);

    // Draw cute glowing rosy cheeks
    final Paint cheekPaint = Paint()
      ..color = const Color(0xFFFF85A1).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx - radius * 0.55, cy + radius * 0.2), radius * 0.22, cheekPaint);
    canvas.drawCircle(Offset(cx + radius * 0.55, cy + radius * 0.2), radius * 0.22, cheekPaint);

    // Draw cute little smiley mouth (v)
    final Paint mouthPaint = Paint()
      ..color = const Color(0xFF7B526F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Path mouthPath = Path()
      ..moveTo(cx - radius * 0.12, cy + radius * 0.18)
      ..quadraticBezierTo(
        cx, cy + radius * 0.36, // Down peak
        cx + radius * 0.12, cy + radius * 0.18,
      );
    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Particle class for petal sparkles
class _PetalParticle {
  final double angle;
  final double radius;
  final double speed;
  final double size;
  final Color color;

  _PetalParticle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.size,
    required this.color,
  });
}
