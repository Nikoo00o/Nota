import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialogOverlayPage extends StatelessWidget {
  final Widget child;

  const DialogOverlayPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DialogOverlayBloc>(
      create: (_) => sl<DialogOverlayBloc>(),
      child: BlocBuilder<DialogOverlayBloc, DialogOverlayState>(
        builder: (BuildContext context, DialogOverlayState state) {
          return Container(key: state.dialogOverlayKey, child: child);
        },
      ),
    );
  }

  /// returns the bloc of the page
  DialogOverlayBloc currentBloc(BuildContext context) => BlocProvider.of<DialogOverlayBloc>(context);

  /// returns the theme data
  ThemeData theme(BuildContext context) => Theme.of(context);
}
