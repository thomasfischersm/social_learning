import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/storage_functions.dart';

class DownloadUrlCacheState extends ChangeNotifier {
  static const Duration cacheTtl = Duration(hours: 1);
  Map<String, _CachedDownloadUrl> _cache = {};

  Future<String?> getDownloadUrl(String? storagePath) async {
    if (storagePath == null) {
      return null;
    }

    _CachedDownloadUrl? cachedEntry = _cache[storagePath];
    DateTime now = DateTime.now();
    if (cachedEntry != null && cachedEntry.expiresAt.isAfter(now)) {
      return cachedEntry.url;
    }

    try {
      String url = await StorageFunctions.getDownloadUrl(storagePath);
      DateTime expiresAt = now.add(cacheTtl);
      _cache[storagePath] = _CachedDownloadUrl(url, expiresAt);
      return url;
    } catch (_) {
      _cache.remove(storagePath);
      return null;
    }
  }

  void invalidate(String? storagePath) {
    if (storagePath == null) {
      return;
    }
    _cache.remove(storagePath);
  }

  void clear() {
    _cache.clear();
  }
}

class _CachedDownloadUrl {
  String url;
  DateTime expiresAt;

  _CachedDownloadUrl(this.url, this.expiresAt);
}
