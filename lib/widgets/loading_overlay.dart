import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A simple blocking spinner overlay for async actions that aren't already
/// driven by a CartoonButton's own `isLoading` state (e.g. grid taps, row
/// taps, or actions kicked off after a dialog has already closed).
class LoadingOverlay {
  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(140),
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryYellow),
      ),
    ).then((_) => _isShowing = false);
  }

  static void hide(BuildContext context) {
    if (!_isShowing) return;
    _isShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }
}
