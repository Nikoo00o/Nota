import 'package:app/core/enums/dialog_status.dart';
import 'package:app/core/get_it.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_bloc.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_event.dart';
import 'package:app/presentation/main/dialog_overlay/dialog_overlay_state.dart';
import 'package:app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DialogOverlayPage extends StatelessWidget {
  static const int _duration = 100;

  final NavigationService navigationService;

  final Widget child;

  const DialogOverlayPage({required this.navigationService, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DialogOverlayBloc>(
      create: (_) => sl<DialogOverlayBloc>(),
      child: BlocBuilder<DialogOverlayBloc, DialogOverlayState>(
        builder: (BuildContext context, DialogOverlayState state) {
          return Stack(children: <Widget>[
            child,
            _buildDialogOverlay(context, state),
          ]);
          // overlay must be here
        },
      ),
    );
  }

  Widget _buildDialogOverlay(BuildContext context, DialogOverlayState state) {
    final bool isDialogVisible = state.dialogStatus != DialogStatus.HIDDEN;
    return AnimatedOpacity(
      opacity: isDialogVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: _duration),
      child: IgnorePointer(
        ignoring: !isDialogVisible,
        child: Container(
          color: Colors.white.withOpacity(0.7),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: _duration),
            child: _buildDialog(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(BuildContext context, DialogOverlayState state) {
    switch (state.dialogStatus) {
      case DialogStatus.ERROR:
        return _buildErrorDialog(context, state);
      case DialogStatus.LOADING:
        return _buildLoadingDialog(context, state);
      case DialogStatus.CONFIRM:
        return _buildConfirmDialog(context, state);
      case DialogStatus.HIDDEN:
      default:
        return const SizedBox();
    }
  }

  Widget _buildErrorDialog(BuildContext context, DialogOverlayState state) {
    return AlertDialog(
      title: const Text("TEST DIALOG ERROR"),
      content: const Text('A dialog is a type of modal window that\n'
          'appears in front of app content to\n'
          'provide critical information, or prompt\n'
          'for a decision to be made.'),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text("Cancel"),
          onPressed: () {
            currentBloc(context).add(HideDialog());
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text("Apply"),
          onPressed: () {
            currentBloc(context).add(HideDialog());
          },
        ),
      ],
    );
  }

  Widget _buildConfirmDialog(BuildContext context, DialogOverlayState state) {
    return AlertDialog(
      title: const Text("TEST DIALOG CONFIRM"),
      content: const Text('A dialog is a type of modal window that\n'
          'appears in front of app content to\n'
          'provide critical information, or prompt\n'
          'for a decision to be made.'),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text("Cancel"),
          onPressed: () {
            currentBloc(context).add(HideDialog());
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text("Apply"),
          onPressed: () {
            currentBloc(context).add(HideDialog());
          },
        ),
      ],
    );
  }

  Widget _buildLoadingDialog(BuildContext context, DialogOverlayState state) {
    return AlertDialog(
      title: const Text("TEST DIALOG LOADING"),
      content: const Text('A dialog is a type of modal window that\n'
          'appears in front of app content to\n'
          'provide critical information, or prompt\n'
          'for a decision to be made.'),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text("Cancel"),
          onPressed: () {
            currentBloc(context).add(HideDialog());
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text("Apply"),
          onPressed: () {
            currentBloc(context).add(HideDialog());
          },
        ),
      ],
    );
  }

  /// returns the bloc of the page
  DialogOverlayBloc currentBloc(BuildContext context) => BlocProvider.of<DialogOverlayBloc>(context);

  /// returns the theme data
  ThemeData theme(BuildContext context) => Theme.of(context);
}
