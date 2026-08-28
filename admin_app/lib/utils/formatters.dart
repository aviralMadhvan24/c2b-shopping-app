import 'package:intl/intl.dart';

/// Money is always rupees in this store, formatted the Indian way
/// (₹1,23,456) because that is how the owner reads a number.
class Money {
  static final _full = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _precise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount) => _full.format(amount);

  /// Paise shown — for a line total the customer was actually charged.
  static String exact(num amount) => _precise.format(amount);

  /// Tight form for chart axes and stat tiles: ₹1.2L, ₹45.6K, ₹800.
  static String compact(num amount) {
    final value = amount.abs();
    if (value >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.round()}';
  }
}

class Dates {
  static final _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final _date = DateFormat('d MMM yyyy');
  static final _shortDate = DateFormat('d MMM');
  static final _weekday = DateFormat('EEE');

  static String dateTime(DateTime d) => _dateTime.format(d);
  static String date(DateTime d) => _date.format(d);
  static String short(DateTime d) => _shortDate.format(d);
  static String weekday(DateTime d) => _weekday.format(d);

  /// "2 hours ago" — how an owner scanning a list of orders thinks about time.
  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.isNegative) return 'just now';
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return _date.format(d);
  }
}
