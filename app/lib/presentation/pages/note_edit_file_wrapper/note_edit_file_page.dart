import 'package:app/domain/entities/structure_item.dart';
import 'package:app/presentation/pages/note_edit/widgets/note_bottom_bar.dart';
import 'package:app/presentation/pages/note_edit_file_wrapper/note_edit_file_bloc.dart';
import 'package:app/presentation/pages/note_edit_file_wrapper/note_edit_file_state.dart';
import 'package:app/presentation/widgets/base_note/base_note_page.dart';
import 'package:app/presentation/widgets/base_pages/bloc_page.dart';
import 'package:flutter/material.dart';
import 'package:shared/core/constants/error_codes.dart';
import 'package:shared/core/enums/supported_file_types.dart';
import 'package:shared/core/exceptions/exceptions.dart';

final class NoteEditFilePage extends BaseNotePage<NoteEditFileBloc, NoteEditFileState> {
  const NoteEditFilePage() : super();

  @override
  Widget buildBodyWithNoState(BuildContext context, Widget bodyWithState) {
    return Scrollbar(
      controller: currentBloc(context).scrollController,
      child: createBlocBuilder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context, NoteEditFileState state) {
    if (state.isInitialized) {
      final SupportedFileTypes fileType = SupportedFileTypes.fromString(state.content!.fileExtension);
      switch (fileType) {
        case SupportedFileTypes.txt:
          throw const ClientException(message: ErrorCodes.INVALID_PARAMS);
        case SupportedFileTypes.jpg:
        case SupportedFileTypes.jpeg:
        case SupportedFileTypes.png:
          return _buildImageView(context, state);
        case SupportedFileTypes.pdf:
          return _buildPdfView(context, state);
      }
    }
    return const SizedBox();
  }

  Widget _buildImageView(BuildContext context, NoteEditFileState state) {
    final String fileInfo = translate(context, "image", keyParams: <String>[state.content?.fileName ?? ""]);
    final String time = translate(context, "from", keyParams: <String>[
      state.content?.fileLastModified.toString() ?? "",
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: InteractiveViewer(
              minScale: 0.01,
              maxScale: 100,
              child: Image.memory(state.content!.content, fit: BoxFit.fill),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text("$fileInfo $time"),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildPdfView(BuildContext context, NoteEditFileState state) {
    // todo: implement
    throw UnimplementedError("todo: implement");
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return PreferredSize(
      // default size
      preferredSize: const Size.fromHeight(BlocPage.defaultAppBarHeight),
      child: createBlocSelector<StructureItem?>(
        selector: (NoteEditFileState state) => state.currentItem,
        builder: (BuildContext context, StructureItem? currentItem) {
          if (currentItem == null) {
            return AppBar(); // use empty app bar at first, so that the element gets cached for performance
          } else {
            return buildTitleAppBar(context, currentItem, withBackButton: true);
          }
        },
      ),
    );
  }

  @override
  Widget buildBottomBar(BuildContext context) => const NoteBottomBar<NoteEditFileBloc, NoteEditFileState>();

  @override
  String get pageName => "note edit file";
}
