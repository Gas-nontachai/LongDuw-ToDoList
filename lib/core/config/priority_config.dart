import '../../l10n/app_localizations.dart';

class PriorityConfig {
  PriorityConfig._();

  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';

  static const values = [low, medium, high];

  static Map<String, String> options(AppLocalizations l10n) => {
    low: l10n.priorityLow,
    medium: l10n.priorityMedium,
    high: l10n.priorityHigh,
  };
}
