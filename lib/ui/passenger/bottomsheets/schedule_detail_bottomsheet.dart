import 'package:drup/resources/app_dimen.dart';
import 'package:flutter/material.dart';

class ScheduleDetailBottomSheet extends StatelessWidget {
  const ScheduleDetailBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Corners.lg),
          topRight: Radius.circular(Corners.lg),
        ),
      ),
      padding: EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [],
        ),
      ),
    );
  }
}
