class AppConstants {
  static const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String monthName(int month) => months[month - 1];
  static int monthIndex(String name) => months.indexOf(name) + 1;
}
