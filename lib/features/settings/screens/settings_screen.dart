import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
  });
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isThai = Localizations.localeOf(context).languageCode == 'th';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
      children: [
        Card(
          child: SwitchListTile(
            secondary: const Icon(CupertinoIcons.moon),
            title: Text(l10n.switchToDarkMode),
            value: isDark,
            onChanged: (dark) =>
                onThemeModeChanged(dark ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(CupertinoIcons.globe),
            title: Text(l10n.changeLanguage),
            trailing: Text(isThai ? l10n.thai : l10n.english),
            onTap: () => onLocaleChanged(Locale(isThai ? 'en' : 'th')),
          ),
        ),
      ],
    );
  }
}
