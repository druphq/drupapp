import 'package:drup/core/animation/slide_animation.dart';
import 'package:drup/resources/drup_icons.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';

class DrupLogoAnimation extends StatefulWidget {
  const DrupLogoAnimation({super.key});

  @override
  DrupLogoAnimationState createState() => DrupLogoAnimationState();
}

class DrupLogoAnimationState extends State<DrupLogoAnimation>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  bool showText = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Adjust duration as needed
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoController.forward();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showText = true;
      });
      _textController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Animated D logo dropping from above
          SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, -2), // Start position (above screen)
                  end: const Offset(0, 0), // End position (center of screen)
                ).animate(
                  CurvedAnimation(
                    parent: _logoController,
                    curve: const Interval(
                      0,
                      0.5,
                      curve: Curves.linearToEaseOut,
                    ), // Animation curve
                  ),
                ),
            child: const Icon(
              DrupIcons.drupIcon,
              size: 80,
              color: Colors.white,
            ), // Replace with your D logo asset
          ),
          //slide in the text appearing one by one
          Visibility(
            visible: showText,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(
                      -0.4,
                      0,
                    ), // Start position (left of screen)
                    end: const Offset(
                      -0.1,
                      0,
                    ), // End position (center of screen)
                  ).animate(
                    CurvedAnimation(
                      parent: _textController,
                      curve: Curves.easeOut,
                    ),
                  ),
              child: FadeTransition(
                opacity: _textController,
                child: SizedBox(
                  width: 110,
                  height: 60,
                  child: animatedTextList('rup'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget animatedTextList(String items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      primary: false,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return SlideAnimation(
          position: index,
          itemCount: items.length,
          slideDirection: SlideDirection.fromRight,
          animationController: _textController,
          child: Text(
            items[index],
            style: TextStyles.montserrat.copyWith(
              fontSize: 60,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
