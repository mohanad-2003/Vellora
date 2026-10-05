import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Clears what the app can re-download: product photos on disk (the
/// `cached_network_image` store) and decoded images in memory. The session,
/// bag, favourites and preferences are untouched.
Future<void> clearImageCache() async {
  await DefaultCacheManager().emptyCache();
  final images = PaintingBinding.instance.imageCache;
  images.clear();
  images.clearLiveImages();
}
