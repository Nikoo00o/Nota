import 'dart:typed_data';

import 'package:app/core/utils/argon_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/core/utils/security_utils.dart';

/// Just takes some bytes of each [bytes] and [saltBytes]
class ArgonWrapperMock extends ArgonWrapper {
  @override
  Future<List<int>> hashBytesSecure(List<int> bytes, List<int> saltBytes, int hashLength) async {
    final List<int> input = List<int>.from(bytes);
    input.addAll(saltBytes);

    final List<int> output = List<int>.empty(growable: true);
    final Uint8List hashed = SecurityUtils.hashBytes(Uint8List.fromList(input));

    for (int i = 0; i < hashLength; ++i) {
      output.add(hashed.elementAt(i % hashed.length));
    }

    return output;
  }
}
