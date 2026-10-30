import '../../../core/localization/app_localizations.dart';

class OrderDateFormatter {
  OrderDateFormatter._();

  static const List<String> _monthsEn = [
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

  static const List<String> _monthsKm = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];

  static String format(
    String? isoDate,
    AppLocalizations l10n, {
    bool includeTime = true,
  }) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final monthName =
          l10n.isKhmer ? _monthsKm[dt.month - 1] : _monthsEn[dt.month - 1];
      final dateStr = '${dt.day} $monthName ${dt.year}';
      if (!includeTime) return dateStr;
      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$dateStr  •  $timeStr';
    } catch (_) {
      return isoDate;
    }
  }
}
