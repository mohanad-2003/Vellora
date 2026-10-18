import 'package:flutter/material.dart';

/// Colour names the shop uses for product variants (`Burgundy`, `Rose Gold`…),
/// with a swatch and an Arabic name for each. A name that is not listed still
/// works: it gets a grey swatch and is shown as typed.
class ProductColors {
  ProductColors._();

  static const _grey = Color(0xFF9AA1B0);

  // name (lower case, single spaces) -> (swatch, Arabic name)
  static const Map<String, (Color, String)> _known = {
    'black': (Color(0xFF16181F), 'أسود'),
    'white': (Color(0xFFFFFFFF), 'أبيض'),
    'red': (Color(0xFFE5484D), 'أحمر'),
    'navy': (Color(0xFF1F2A5A), 'كحلي'),
    'sand': (Color(0xFFD9C5A0), 'رملي'),
    'olive': (Color(0xFF6B7A3A), 'زيتي'),
    'burgundy': (Color(0xFF6E2A3C), 'بورغندي'),
    'maroon': (Color(0xFF6B1F2A), 'عنابي'),
    'glacier': (Color(0xFFB9D3E6), 'جليدي'),
    'silver': (Color(0xFFC8CCD2), 'فضي'),
    'gold': (Color(0xFFD4AF37), 'ذهبي'),
    'rose gold': (Color(0xFFB76E79), 'ذهبي وردي'),
    'titanium': (Color(0xFF8D8A85), 'تيتانيوم'),
    'natural titanium': (Color(0xFF9A948B), 'تيتانيوم طبيعي'),
    'space gray': (Color(0xFF53565A), 'رمادي فلكي'),
    'space grey': (Color(0xFF53565A), 'رمادي فلكي'),
    'midnight': (Color(0xFF1C2233), 'منتصف الليل'),
    'starlight': (Color(0xFFF0E6D8), 'ضوء النجوم'),
    'blue': (Color(0xFF2563EB), 'أزرق'),
    'light blue': (Color(0xFF93C5FD), 'أزرق فاتح'),
    'green': (Color(0xFF16A34A), 'أخضر'),
    'dark green': (Color(0xFF14532D), 'أخضر داكن'),
    'teal': (Color(0xFF0D9488), 'تركوازي مخضر'),
    'turquoise': (Color(0xFF2DD4BF), 'فيروزي'),
    'mint': (Color(0xFFA7F3D0), 'نعناعي'),
    'yellow': (Color(0xFFF5C518), 'أصفر'),
    'orange': (Color(0xFFF97316), 'برتقالي'),
    'coral': (Color(0xFFFF7F6B), 'مرجاني'),
    'pink': (Color(0xFFEC4899), 'وردي'),
    'purple': (Color(0xFF7C3AED), 'بنفسجي'),
    'lavender': (Color(0xFFC4B5FD), 'خزامي'),
    'brown': (Color(0xFF7B4B2A), 'بني'),
    'tan': (Color(0xFFC8A27A), 'بني فاتح'),
    'khaki': (Color(0xFFB5A26B), 'كاكي'),
    'beige': (Color(0xFFE4D5B7), 'بيج'),
    'cream': (Color(0xFFF5EBD7), 'كريمي'),
    'gray': (Color(0xFF9AA1B0), 'رمادي'),
    'grey': (Color(0xFF9AA1B0), 'رمادي'),
    'charcoal': (Color(0xFF36393F), 'فحمي'),
  };

  /// Case, extra spaces, `-` and `_` do not matter: `Rose-Gold` is `rose gold`.
  static String _key(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[-_]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  /// The swatch for [name], grey when the name is not known.
  static Color swatch(String name) => _known[_key(name)]?.$1 ?? _grey;

  /// The Arabic name for [name], or null when it has none.
  static String? arabic(String name) => _known[_key(name)]?.$2;

  /// The name to show: Arabic for an Arabic app when the colour is known, the
  /// name as written otherwise.
  static String label(String name, String languageCode) =>
      languageCode == 'ar' ? (arabic(name) ?? name) : name;
}
