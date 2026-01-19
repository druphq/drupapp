import 'package:flutter/material.dart';

class SearchingRipple extends StatefulWidget {
  const SearchingRipple({
    super.key,
    required this.primaryColor,
    this.secondaryColor = Colors.white,
    this.duration = const Duration(milliseconds: 1500),
    this.size = 280,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final double size;
  final Duration duration;

  @override
  State<SearchingRipple> createState() => _SearchingRippleState();
}

class _SearchingRippleState extends State<SearchingRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    // Scale from small to large
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Fade out as it grows
    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(SearchingRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size * 0.5,
                    height: widget.size * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.primaryColor, width: 3),
                    ),
                  ),
                ),
              );
            },
          ),
          // Center dot
          Container(
            width: widget.size * 0.08,
            height: widget.size * 0.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
