import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class SoftwareLicensesScreen extends StatefulWidget {
  const SoftwareLicensesScreen({super.key});

  @override
  State<SoftwareLicensesScreen> createState() => _SoftwareLicensesScreenState();
}

class _SoftwareLicensesScreenState extends State<SoftwareLicensesScreen> {
  late Future<Map<String, List<LicenseEntry>>> _licenses = _loadLicenses();

  Future<Map<String, List<LicenseEntry>>> _loadLicenses() async {
    final packages = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final package in entry.packages) {
        packages.putIfAbsent(package, () => []).add(entry);
      }
    }
    return packages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.softwareLicenses)),
      body: FutureBuilder<Map<String, List<LicenseEntry>>>(
        future: _licenses,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _licenses = _loadLicenses()),
                child: Text(l10n.retry),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final packages = snapshot.data!;
          final names = packages.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: names.length,
            itemBuilder: (context, index) {
              final name = names[index];
              return ListTile(
                title: Text(name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => _LicenseDetails(
                      package: name,
                      entries: packages[name]!,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LicenseDetails extends StatelessWidget {
  const _LicenseDetails({required this.package, required this.entries});

  final String package;
  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(package)),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: 32),
                for (final paragraph in entries[i].paragraphs)
                  Padding(
                    padding: EdgeInsets.only(
                      left: paragraph.indent < 0 ? 0 : paragraph.indent * 16.0,
                      bottom: 12,
                    ),
                    child: Text(
                      paragraph.text,
                      textAlign:
                          paragraph.indent == LicenseParagraph.centeredIndent
                          ? TextAlign.center
                          : TextAlign.start,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
