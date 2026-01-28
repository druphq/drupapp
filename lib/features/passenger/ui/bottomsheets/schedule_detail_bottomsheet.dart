import 'package:drup/core/widgets/custom_button.dart';
import 'package:drup/resources/app_dimen.dart';
import 'package:drup/theme/app_colors.dart';
import 'package:drup/theme/app_style.dart';
import 'package:drup/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ScheduleDetailBottomSheet extends StatefulWidget {
  final VoidCallback? onConfirm;

  const ScheduleDetailBottomSheet({super.key, this.onConfirm});

  @override
  State<ScheduleDetailBottomSheet> createState() =>
      _ScheduleDetailBottomSheetState();
}

class _ScheduleDetailBottomSheetState extends State<ScheduleDetailBottomSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              secondary: AppColors.accent,
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.onAccent,
              tertiary: AppColors.accent,
              onTertiary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: TextStyles.t1.copyWith(
                  fontSize: FontSizes.s18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      useRootNavigator: false,
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: context.theme.copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.accent,
                onPrimary: Colors.white,
                secondary: AppColors.accent,
                onSecondary: Colors.white,
                surface: Colors.white,
                onSurface: AppColors.onAccent,
                tertiary: AppColors.accent,
                onTertiary: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  textStyle: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool get _canConfirm => _selectedDate != null && _selectedTime != null;

  String _formatTimeWithAmPm(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getStartTime() {
    if (_selectedTime == null) return '';

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final startTime = selectedDateTime.subtract(const Duration(minutes: 10));
    final startTimeOfDay = TimeOfDay(
      hour: startTime.hour,
      minute: startTime.minute,
    );

    return _formatTimeWithAmPm(startTimeOfDay);
  }

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
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pick-up details',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onAccent,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.onAccent),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Gap(8),
            Text(
              'Select your preferred pickup date and time',
              style: TextStyles.t2.copyWith(
                fontSize: FontSizes.s14,
                color: AppColors.textSecondary,
              ),
            ),
            Gap(24),

            // Pickup Date
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(Corners.hMd),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Corners.hMd),
                  color: AppColors.grey50,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyStrong,
                      ),
                    ),
                    Gap(4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate != null
                                ? DateFormat(
                                    'EEEE, MMMM d',
                                  ).format(_selectedDate!)
                                : 'Select date',
                            style: TextStyles.t2.copyWith(
                              fontSize: FontSizes.s20,
                              color: _selectedDate != null
                                  ? AppColors.onAccent
                                  : AppColors.textSecondary,
                              fontWeight: _selectedDate != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Gap(20),

            // Pickup Date
            InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(Corners.hMd),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Corners.hMd),
                  color: AppColors.grey50,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup Time
                    Text(
                      'Time',
                      style: TextStyles.t2.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyStrong,
                      ),
                    ),
                    Gap(4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTime != null
                                ? _formatTimeWithAmPm(_selectedTime!)
                                : 'Select time',
                            style: TextStyles.t2.copyWith(
                              fontSize: FontSizes.s20,
                              color: _selectedTime != null
                                  ? AppColors.onAccent
                                  : AppColors.textSecondary,
                              fontWeight: _selectedTime != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Gap(20),
            if (_selectedTime != null)
              Text.rich(
                TextSpan(
                  text: 'Get ready for pick-up between\t',
                  style: TextStyles.t1.copyWith(
                    fontSize: FontSizes.s18,
                    color: AppColors.greyStronger,
                  ),
                  children: [
                    TextSpan(
                      text: _getStartTime(),
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(text: '\tand\t'),
                    TextSpan(
                      text: _formatTimeWithAmPm(_selectedTime!),
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

            Gap(24),

            // Confirm Button
            CustomButton(
              text: 'Confirm',
              onPressed: _canConfirm
                  ? () {
                      widget.onConfirm?.call();
                    }
                  : () {},
              isLoading: false,
            ),

            Gap(24),

            // Terms note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text:
                          'By ordering a scheduled ride, you confirm that you have read and accepted',
                      style: TextStyles.t1.copyWith(
                        fontSize: FontSizes.s16,
                        color: AppColors.greyStrong,
                      ),
                      children: [
                        TextSpan(
                          text: '\tthe terms of scheduled rides.',
                          style: TextStyles.t1.copyWith(
                            fontSize: FontSizes.s16,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.greyStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
