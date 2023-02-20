import 'dart:math';

import 'package:app/core/utils/argon_wrapper.dart';

/// Just takes some bytes of each [bytes] and [saltBytes]
class ArgonWrapperMock extends ArgonWrapper {
  @override
  Future<List<int>> hashBytesSecure(List<int> bytes, List<int> saltBytes, int hashLength) async {
    final List<int> newBytes = List<int>.empty(growable: true);
    int first = 0;
    int second = 0;
    for (int i = 0; i < hashLength; ++i) {
      if (i % 2 == 0 && first < bytes.length) {
        newBytes.add(bytes[first++]);
      } else if (second < saltBytes.length) {
        newBytes.add(saltBytes[second++]);
      } else {
        newBytes.add(65);
      }
    }
    return newBytes;
  }
}
