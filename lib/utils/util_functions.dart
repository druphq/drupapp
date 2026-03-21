// Add comma to amounts
String formatThousand(double number) {
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

// format duration to something like 1h 30m or 30m
String formatDuration(int seconds) {
  int minutes = (seconds / 60).ceil(); // important!

  if (minutes >= 60) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  return '${minutes}m';
}

// format distance to something like 1.5 km
String formatDistance(double meters) {
  final km = meters / 1000;

  if (km < 1) {
    // short distance → more precision
    return '${km.toStringAsFixed(2)} km';
  } else {
    // normal distance
    return '${km.toStringAsFixed(1)} km';
  }
}

// Format ride type,eg individual or shared_3
// capitalize first letter and replace _ with space
String formatRideType(String rideType) {
  if (rideType.isEmpty) return '';
  String formatted = rideType.replaceAll('_', ' ');
  return formatted[0].toUpperCase() + formatted.substring(1);
}

// Format date time to something like  3 days at 10:30 AM or 1 week at 10:30 AM
// if the day is today then return only time
String formatRelativeDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = targetDay.difference(today).inDays;
  final absDiff = diff.abs();
  final time = _formatTimeOfDay(dateTime);

  if (absDiff == 0) {
    return time;
  } else if (absDiff == 1) {
    return diff > 0 ? 'Tomorrow at $time' : 'Yesterday at $time';
  } else if (absDiff < 7) {
    return '$absDiff days at $time';
  } else {
    final weeks = (absDiff / 7).floor();
    return '$weeks week${weeks > 1 ? 's' : ''} at $time';
  }
}

// format date to something like June 5, 2024
String formatDate(DateTime dateTime) {
  return '${_getMonthName(dateTime.month)} ${dateTime.day}';
}

// return end date by adding duration to start date and format it to something like 10:30 AM
String calculateEndDate(DateTime endDate, int durationMinutes) {
  return formatTime(endDate.add(Duration(seconds: durationMinutes)));
}

//format date time to something like June 5, 2024 10:30 AM
String formatDateTime(DateTime dateTime) {
  final formattedTime = _formatTimeOfDay(dateTime);
  final formattedDate =
      '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
  return '$formattedDate, $formattedTime';
}

// format date time to something like 10:30 AM June 5, 2024
String formatTimeDate(DateTime dateTime) {
  final formattedTime = _formatTimeOfDay(dateTime);
  final formattedDate =
      '${_getMonthName(dateTime.month)} ${dateTime.day}, ${dateTime.year}';
  return '$formattedTime, $formattedDate';
}

// format time to something like 10:30 AM
String formatTime(DateTime dateTime) {
  return _formatTimeOfDay(dateTime);
}

String formatMonthYear(DateTime dateTime) {
  return '${_getMonthName(dateTime.month)} ${dateTime.year}';
}

// format pickup window to something like 10:00 AM
String _formatTimeOfDay(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final displayMinute = minute.toString().padLeft(2, '0');
  return '$displayHour:$displayMinute $period';
}

String _getMonthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

String formatShortDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
