import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_loading.dart';
import '../services/update_controller.dart';

/// Outside the app Navigator: pushed routes and incoming links stay behind it.
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.controller, required this.child});

  final UpdateController controller;
  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  bool _backgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.controller.check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgrounded = true;
    } else if (state == AppLifecycleState.resumed && _backgrounded) {
      _backgrounded = false;
      unawaited(widget.controller.check());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final blocked =
          !widget.controller.ready || widget.controller.updateRequired;
      return Stack(
        fit: StackFit.expand,
        children: [
          // Preserve navigation and business state when resuming into a block.
          Offstage(
            offstage: blocked,
            child: ExcludeFocus(
              excluding: blocked,
              child: TickerMode(enabled: !blocked, child: widget.child),
            ),
          ),
          if (blocked)
            HeroControllerScope.none(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => PopScope(
                    canPop: false,
                    child: ListenableBuilder(
                      listenable: widget.controller,
                      builder: (context, _) => widget.controller.updateRequired
                          ? ForceUpdateScreen(controller: widget.controller)
                          : const Scaffold(body: AppLoading()),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key, required this.controller});
  final UpdateController controller;

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _update() async {
    setState(() {
      _opening = true;
      _failed = false;
    });
    try {
      final url = widget.controller.policy?.storeUrl;
      if (url == null ||
          !await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unavailable = widget.controller.policy?.storeUrl == null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.system_update,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      text.forceUpdateTitle,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    text.forceUpdateDescription,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _opening || unavailable ? null : _update,
                    child: Text(
                      _opening ? text.forceUpdateOpening : text.forceUpdateNow,
                    ),
                  ),
                  if (unavailable || _failed) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        unavailable
                            ? text.forceUpdateUnavailable
                            : text.forceUpdateFailed,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
