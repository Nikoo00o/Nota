import 'dart:async';

import 'package:app/presentation/pages/settings/widgets/settings_option.dart';
import 'package:flutter/material.dart';

class SettingsToggleOption extends SettingsOption {
  /// If the option is currently active
  final bool isActive;
  final FutureOr<void> Function(bool active) onChange;

  const SettingsToggleOption({
    required super.titleKey,
    super.titleKeyParams,
    super.descriptionKey,
    super.descriptionKeyParams,
    super.hasBigDescription = false,
    super.iconSize = 30,
    super.icon,
    super.disabled = false,
    required this.isActive,
    required this.onChange,
  });

  @override
  Widget? buildTrailing(BuildContext context) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: isActive,
        onChanged: onChange,
      ),
    );
  }

  @override
  void onTap(BuildContext context) => onChange(!isActive);
}
