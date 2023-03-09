import 'package:app/presentation/widgets/base_pages/page_state.dart';
import 'package:flutter/cupertino.dart';

class DialogOverlayState extends PageState {
  final GlobalKey dialogOverlayKey;

  /// The global key is not used for comparison inside of the state, because it will not change!
  const DialogOverlayState({required this.dialogOverlayKey}) : super(const <String, Object?>{});
}
