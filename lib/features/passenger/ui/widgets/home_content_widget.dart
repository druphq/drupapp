import 'package:drup/di/notifiers.dart';
import 'package:drup/resources/app_assets.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class HomeContentWidget extends ConsumerWidget {
  const HomeContentWidget({
    super.key,
    this.onRideTapped,
    this.onDeliveryTapped,
  });
  final VoidCallback? onRideTapped;
  final VoidCallback? onDeliveryTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //user notifier
    final userNotifier = ref.watch(userNotifierProvider);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.c20)),
        color: AppColors.accent500,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Great to see you, ${userNotifier.user?.firstName ?? 'Guest'}!',
              textAlign: TextAlign.center,
              style: TextStyles.t1.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Gap(20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ContentItemWidget(
                    onTap: onDeliveryTapped,
                    iconPath: AppAssets.deliveryIcon,
                    title: 'Delivery',
                    subtitle: 'Send packages',
                  ),
                ),

                const Gap(10),

                Expanded(
                  child: ContentItemWidget(
                    onTap: onRideTapped,
                    iconPath: AppAssets.calendarRide,
                    title: 'Schedule',
                    subtitle: 'Airport Rides',
                  ),
                ),
              ],
            ),
          ),

          // HorizontalListWidget(
          //   itemCount: 2,
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   itemBuilder: (context, index) {
          //     if (index == 0) {
          //       return ContentItemWidget(
          //         onTap: onWhereToTap,
          //         iconPath: AppAssets.calendarIcon,
          //         title: 'Schedule',
          //         subtitle: 'Airport Rides',
          //       );
          //     }

          //     const Gap(16);

          //     return ContentItemWidget(
          //       onTap: onWhereToTap,
          //       iconPath: AppAssets.deliveryIcon,
          //       title: 'Delivery',
          //       subtitle: 'Send packages',
          //     );
          //   },
          // ),

          // const Gap(16),
          // Container(
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(Corners.lg),
          //     color: AppColors.surface,
          //   ),
          //   margin: const EdgeInsets.symmetric(horizontal: 16),
          //   child: ListTile(
          //     minTileHeight: Sizes.tfieldHeight,
          //     onTap: onWhereToTap,
          //     leading: Container(
          //       width: 16,
          //       height: 16,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         border: Border.fromBorderSide(
          //           BorderSide(color: AppColors.greyStrong, width: 1.5),
          //         ),
          //       ),
          //     ),
          //     minLeadingWidth: 2,
          //     title: Text(
          //       AppStrings.whereToTxt,
          //       style: TextStyles.t2.copyWith(
          //         fontWeight: FontWeight.w600,
          //         color: AppColors.textSecondary,
          //         fontSize: FontSizes.s17,
          //       ),
          //     ),
          //   ),
          // ),
          Gap(MediaQuery.of(context).size.height * 0.08),
        ],
      ),
    );
  }
}

class ContentItemWidget extends StatelessWidget {
  const ContentItemWidget({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    this.width = 30,
    this.onTap,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.c20),
      ),
      color: AppColors.accentLighter,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Image.asset(
                iconPath,
                width: width,
                height: 50,
                fit: BoxFit.contain,
              ),
              const Gap(16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(8),
                    Text(
                      title,
                      style: TextStyles.t1.copyWith(
                        fontSize: 16,
                        color: AppColors.bgBlack,
                      ),
                    ),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyles.body1.copyWith(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
