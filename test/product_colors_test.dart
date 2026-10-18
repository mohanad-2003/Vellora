import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/theme/product_colors.dart';

/// The names a shop writes for a variant (Burgundy, Rose-Gold…) get a swatch
/// and, in Arabic, a name; an unknown name still works.
void main() {
  const grey = Color(0xFF9AA1B0);

  test('the colours of the iPhone 18 Pro are known', () {
    for (final name in ['Burgundy', 'Black', 'Glacier', 'Silver']) {
      expect(ProductColors.swatch(name), isNot(grey), reason: name);
    }
    expect(ProductColors.arabic('Burgundy'), 'بورغندي');
    expect(ProductColors.arabic('Glacier'), 'جليدي');
    expect(ProductColors.arabic('Silver'), 'فضي');
  });

  test('case, spaces and dashes do not matter', () {
    final base = ProductColors.swatch('rose gold');
    expect(ProductColors.swatch('Rose Gold'), base);
    expect(ProductColors.swatch('  rose-gold '), base);
    expect(ProductColors.swatch('ROSE_GOLD'), base);
  });

  test('an unknown name gets a grey swatch and stays as written', () {
    expect(ProductColors.swatch('Mauve'), grey);
    expect(ProductColors.label('Mauve', 'ar'), 'Mauve');
    expect(ProductColors.label('Mauve', 'en'), 'Mauve');
  });

  test('the label follows the language', () {
    expect(ProductColors.label('Burgundy', 'ar'), 'بورغندي');
    expect(ProductColors.label('Burgundy', 'en'), 'Burgundy');
  });
}
