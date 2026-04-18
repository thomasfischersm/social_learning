import 'package:flutter/foundation.dart';

void dprint(Object? message) {
  if (kDebugMode) {
    debugPrint(message.toString());
  }
}