import 'package:app/presentation/pages/settings/widgets/settings_option.dart';
import 'package:flutter/material.dart';

/// Only provides a custom on tap callback that gets called when clicking on the config option.
class SettingsCustomOption extends SettingsOption {
  final VoidCallback _onTap;

  const SettingsCustomOption({
    required super.titleKey,
    super.titleKeyParams,
    super.descriptionKey,
    super.descriptionKeyParams,
    super.hasBigDescription = false,
    super.icon,
    super.disabled = false,
    required VoidCallback onTap,
  }) : _onTap = onTap;

  @override
  Widget? buildTrailing(BuildContext context) => null;

  @override
  void onTap(BuildContext context) => _onTap.call();
}
