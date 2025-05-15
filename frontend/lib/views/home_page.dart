import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'upload_page.dart';
import 'results_page.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    required this.onPressed,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovering = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) async {
        setState(() {
          _isHovering = true;
        });
        // Play hover sound asynchronously
        await _audioPlayer.play(AssetSource('sounds/hover.mp3'));
      },
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [
              widget.color.withOpacity(0.2),
              widget.color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: widget.color.withOpacity(_isHovering ? 0.8 : 0.4),
            width: 1.5,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: widget.onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 24, color: Colors.white),
                const SizedBox(width: 12),
              ],
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.text,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isHovering ? 100 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, widget.color],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  String _errorMessage = '';
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    _scrollController.addListener(() {
      setState(() {
        _appBarOpacity = (_scrollController.offset / 100).clamp(0.0, 0.8);
      });
    });
  }

  void _initializeVideo() async {
    _controller = VideoPlayerController.asset('lib/assets/videos/back.mp4');
    try {
      await _controller.initialize();
      setState(() => _isVideoInitialized = true);
      _controller
        ..setLooping(true)
        ..setVolume(0.0)
        ..play();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTitle() {
    return Stack(
      children: [
        // Text stroke
        Text(
          'Welcome to ResumeWise AI',
          style: GoogleFonts.montserrat(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.blueAccent,
          ),
        ),
        // Main text
        Text(
          'Welcome to ResumeWise AI',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize:25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isVideoInitialized
          ? NotificationListener<ScrollUpdateNotification>(
              onNotification: (notification) => true,
              child: Stack(
                children: [
                  // Video Background
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),

                  // Main Content
                  Center(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // Title without animations
                          _buildTitle(),

                          const SizedBox(height: 40),

                          // Feature Card without animations
                          MouseRegion(
                            onHover: (_) {},
                            onExit: (_) {},
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'Smart CVs for Smarter Job Matches\n'
                                '✨ AI-Powered CV Analysis\n'
                                '📊 Instant ATS Score\n'
                                '🔒 Secure Processing',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Buttons Section
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Upload CV Button
                              MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                onHover: (_) {},
                                onExit: (_) {},
                                child:  CustomButton(
                                text: 'Upload CV',
                                color: Colors.blueAccent,
                                icon: Icons.upload_rounded,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UploadPage()),
                                ),
                              ) 
                              ),

                              const SizedBox(height: 25),
                              CustomButton(
                                text: 'View Results',
                                color: Colors.greenAccent,
                                icon: Icons.analytics_rounded,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ResultsPage()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            Colors.blueAccent.withOpacity(0.0)),
                        strokeWidth: 2,
                      ),
                      RotationTransition(
                        turns: AlwaysStoppedAnimation(45 / 360),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Initializing video...',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}