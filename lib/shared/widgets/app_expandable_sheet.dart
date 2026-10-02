import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A scrollable sheet with persistent actions and an optional full-height view.
class AppExpandableSheet extends StatefulWidget {
  const AppExpandableSheet({
    this.title,
    this.headerActions = const [],
    this.showCloseButton = true,
    required this.body,
    required this.actions,
    super.key,
  });

  final String? title;
  final List<Widget> headerActions;
  final bool showCloseButton;
  final Widget body;
  final List<Widget> actions;

  @override
  State<AppExpandableSheet> createState() => _AppExpandableSheetState();
}

class _AppExpandableSheetState extends State<AppExpandableSheet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboard = MediaQuery.viewInsetsOf(context).bottom;
        final availableHeight = (constraints.maxHeight - keyboard).clamp(
          0.0,
          constraints.maxHeight,
        );
        return Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: AnimatedContainer(
            key: const ValueKey('expandable-sheet'),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            constraints: BoxConstraints(
              minHeight: _expanded ? availableHeight : 0,
              maxHeight:
                  availableHeight * (_expanded || keyboard > 0 ? 1 : .85),
            ),
            child: Material(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_expanded ? 0 : 24),
              ),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.onSurfaceVariant.withValues(alpha: .4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 8, 4),
                      child: IconButtonTheme(
                        data: IconButtonThemeData(
                          style: IconButton.styleFrom(
                            fixedSize: const Size(48, 48),
                            iconSize: 24,
                            padding: const EdgeInsets.all(12),
                            foregroundColor: colors.onSurfaceVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: widget.title == null
                                  ? const SizedBox.shrink()
                                  : Text(
                                      widget.title!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                            ),
                            ...widget.headerActions,
                            IconButton(
                              tooltip: _expanded
                                  ? l10n.collapseSheet
                                  : l10n.expandSheet,
                              icon: Icon(
                                _expanded
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                              ),
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                            ),
                            if (widget.showCloseButton)
                              IconButton(
                                tooltip: MaterialLocalizations.of(context)
                                    .closeButtonTooltip,
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      fit: _expanded ? FlexFit.tight : FlexFit.loose,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                        child: widget.body,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          for (var i = 0; i < widget.actions.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Flexible(child: widget.actions[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
