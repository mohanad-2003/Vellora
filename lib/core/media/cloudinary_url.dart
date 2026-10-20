/// A small, square, face-centred copy of a Cloudinary picture, in the best
/// format the phone supports. Anything that is not a Cloudinary upload address
/// is returned unchanged.
String avatarThumb(String url, {int size = 256}) {
  const marker = '/image/upload/';
  final at = url.indexOf(marker);
  if (!url.startsWith('https://res.cloudinary.com/') || at < 0) return url;
  final cut = at + marker.length;
  return '${url.substring(0, cut)}c_fill,g_face,w_$size,h_$size,f_auto,q_auto/'
      '${url.substring(cut)}';
}
