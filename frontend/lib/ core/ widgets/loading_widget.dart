import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double? progress;
  final bool showProgress;

  const LoadingWidget({
    super.key,
    this.message,
    this.progress,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation
          SizedBox(
            width: 120,
            height: 120,
            child: Lottie.asset(
              'lib/assets/animations/Animation_loading.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress indicator
          if (showProgress && progress != null) ...[
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress! * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Loading message
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final double? progress;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingWidget(
              message: loadingMessage,
              progress: progress,
              showProgress: progress != null,
            ),
          ),
      ],
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = AppTheme.primaryColor,
    this.size = 8.0,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
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
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
