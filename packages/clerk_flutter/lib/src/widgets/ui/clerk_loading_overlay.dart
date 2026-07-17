import 'dart:async';

import 'package:clerk_flutter/src/utils/clerk_auth_config.dart';
import 'package:clerk_flutter/src/widgets/ui/clerk_overlay_host.dart';
import 'package:flutter/widgets.dart';

/// Clerk Loading Overlay
class ClerkLoadingOverlay {
  /// Constructs a [ClerkLoadingOverlay]
  ClerkLoadingOverlay(ClerkAuthConfig config) : _loadingWidget = config.loading;

  /// The delay between an [insertInto] call and the loading overlay
  /// being displayed
  static const startupDuration = Duration(milliseconds: 300);

  /// The minimum amount of time the loading overlay should remain
  /// on screen for
  static const minimumOnScreenDuration = Duration(milliseconds: 800);

  /// The number of [ClerkLoadingOverlay] requests that are currently
  /// pending
  int count = 0;

  Timer? _displayTimer;
  Timer? _hideTimer;
  DateTime _hideAfter = DateTime(0);

  final Widget? _loadingWidget;

  /// Shows the loading overlay
  void insertInto(ClerkOverlay overlay) {
    // no overlay widget was supplied so we dont try and display it
    if (_loadingWidget == null) {
      return;
    }
    // make the display of loading indicator reentrant
    if (++count == 1) {
      _hideTimer?.cancel();
      _hideTimer = null;
      _displayTimer ??= Timer(
        startupDuration,
        () {
          if (!overlay.isDisplaying(_loadingWidget)) {
            _hideAfter = DateTime.timestamp().add(minimumOnScreenDuration);
            overlay.insert(_loadingWidget);
          }
        },
      );
    }
  }

  /// Hides the loading overlay
  void removeFrom(ClerkOverlay overlay) {
    // no overlay widget was supplied so we dont try and remove it
    if (_loadingWidget == null) {
      return;
    }
    // make the display of loading indicator reentrant
    if (count > 0 && --count == 0) {
      _displayTimer?.cancel();
      _displayTimer = null;

      if (_hideTimer == null && overlay.isDisplaying(_loadingWidget)) {
        final now = DateTime.timestamp();
        if (_hideAfter.isBefore(now)) {
          overlay.remove(_loadingWidget);
        } else {
          _hideTimer = Timer(
            _hideAfter.difference(now),
            () {
              _hideTimer = null;
              if (overlay.mounted) {
                overlay.remove(_loadingWidget);
              }
            },
          );
        }
      }
    }
  }
}
