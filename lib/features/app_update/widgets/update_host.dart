import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../services/update_controller.dart';

/// Checks in the background and leaves the app usable while an update is available.
class UpdateHost extends StatefulWidget {
  const UpdateHost({super.key, required this.controller, required this.child});

  final UpdateController controller;
  final Widget child;

  @override
  State<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends State<UpdateHost> with WidgetsBindingObserver {
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
      final visible = widget.controller.updateAvailable;
      return Column(
        children: [
          if (visible)
            SafeArea(
              bottom: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .45,
                ),
                child: SingleChildScrollView(
                  child: UpdateNotice(controller: widget.controller),
                ),
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: visible,
              child: widget.child,
            ),
          ),
        ],
      );
    },
  );
}

class UpdateNotice extends StatefulWidget {
  const UpdateNotice({super.key, required this.controller});
  final UpdateController controller;

  @override
  State<UpdateNotice> createState() => _UpdateNoticeState();
}

class _UpdateNoticeState extends State<UpdateNotice> {
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
    return MaterialBanner(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              text.appUpdateTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(text.appUpdateDescription),
          if (unavailable || _failed) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                unavailable ? text.appUpdateUnavailable : text.appUpdateFailed,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.controller.dismiss,
          child: Text(text.appUpdateLater),
        ),
        TextButton(
          onPressed: _opening || unavailable ? null : _update,
          child: Text(_opening ? text.appUpdateOpening : text.appUpdateNow),
        ),
      ],
    );
  }
}
