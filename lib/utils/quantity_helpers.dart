String normalizeDosageForm(String? dosageForm) {
  final value = (dosageForm ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );

  switch (value) {
    case 'tab':
    case 'tablet':
    case 'tablets':
      return 'tablet';
    case 'cap':
    case 'capsule':
    case 'capsules':
      return 'capsule';
    case 'syrup':
      return 'syrup';
    case 'suspension':
      return 'suspension';
    case 'oral_solution':
    case 'solution':
      return 'oral_solution';
    case 'oral_drop':
    case 'oral_drops':
    case 'drops':
      return 'oral_drops';
    case 'cream':
      return 'cream';
    case 'ointment':
      return 'ointment';
    case 'gel':
      return 'gel';
    case 'emulgel':
      return 'emulgel';
    case 'ampoule':
    case 'ampule':
    case 'ampoules':
      return 'ampoule';
    case 'vial':
    case 'vial_powder':
    case 'vials':
      return 'vial';
    case 'suppository':
    case 'suppositories':
      return 'suppository';
    case 'sachet':
    case 'sachets':
      return 'sachet';
    case 'patch':
    case 'topical_patch':
      return 'patch';
    default:
      return value.isEmpty ? 'unknown' : value;
  }
}

String normalizeQuantityUnit(String? quantityUnit) {
  final value = (quantityUnit ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );

  switch (value) {
    case 'tab':
    case 'tabs':
    case 'tablet':
    case 'tablets':
      return 'tablet';
    case 'cap':
    case 'caps':
    case 'capsule':
    case 'capsules':
      return 'capsule';
    case 'milliliter':
    case 'millilitre':
    case 'ml':
      return 'ml';
    case 'drop':
    case 'drops':
      return 'drops';
    case 'gram':
    case 'grams':
    case 'g':
      return 'g';
    case 'ampoule':
    case 'ampoules':
    case 'ampule':
    case 'ampules':
      return 'ampoule';
    case 'vial':
    case 'vials':
      return 'vial';
    case 'patch':
    case 'patches':
      return 'patch';
    case 'suppository':
    case 'suppositories':
      return 'suppository';
    case 'sachet':
    case 'sachets':
      return 'sachet';
    case 'unit':
    case 'units':
    case '':
      return 'unit';
    default:
      return value;
  }
}

String quantityUnitForDosageForm(String? dosageForm) {
  switch (normalizeDosageForm(dosageForm)) {
    case 'tablet':
      return 'tablet';
    case 'capsule':
      return 'capsule';
    case 'syrup':
    case 'suspension':
    case 'oral_solution':
      return 'ml';
    case 'oral_drops':
      return 'drops';
    case 'gel':
    case 'emulgel':
    case 'cream':
    case 'ointment':
      return 'g';
    case 'ampoule':
      return 'ampoule';
    case 'vial':
      return 'vial';
    case 'suppository':
      return 'suppository';
    case 'sachet':
      return 'sachet';
    case 'patch':
      return 'patch';
    default:
      return 'unit';
  }
}

String getQuantityUnitLabel(String? quantityUnit, {String locale = 'en'}) {
  final isAr = locale == 'ar';
  switch (normalizeQuantityUnit(quantityUnit)) {
    case 'tablet':
      return isAr ? 'قرص' : 'tablet';
    case 'capsule':
      return isAr ? 'كبسولة' : 'capsule';
    case 'ml':
      return isAr ? 'مل' : 'ml';
    case 'drops':
      return isAr ? 'نقطة' : 'drops';
    case 'g':
      return isAr ? 'جم' : 'g';
    case 'ampoule':
      return isAr ? 'أمبول' : 'ampoule';
    case 'vial':
      return isAr ? 'فيال' : 'vial';
    case 'patch':
      return isAr ? 'لاصقة' : 'patch';
    case 'suppository':
      return isAr ? 'لبوسة' : 'suppository';
    case 'sachet':
      return isAr ? 'كيس' : 'sachet';
    default:
      return isAr ? 'وحدة' : 'unit';
  }
}

String getMedicationTypeLabel(String? dosageForm, {String locale = 'en'}) {
  final isAr = locale == 'ar';
  switch (normalizeDosageForm(dosageForm)) {
    case 'tablet':
      return isAr ? 'أقراص' : 'Tablet';
    case 'capsule':
      return isAr ? 'كبسولات' : 'Capsule';
    case 'syrup':
      return isAr ? 'شراب' : 'Syrup';
    case 'suspension':
      return isAr ? 'معلق' : 'Suspension';
    case 'oral_solution':
      return isAr ? 'محلول فموي' : 'Oral solution';
    case 'oral_drops':
      return isAr ? 'نقط فموية' : 'Oral drops';
    case 'gel':
      return isAr ? 'جل' : 'Gel';
    case 'emulgel':
      return isAr ? 'إيمولجل' : 'Emulgel';
    case 'cream':
      return isAr ? 'كريم' : 'Cream';
    case 'ointment':
      return isAr ? 'مرهم' : 'Ointment';
    case 'ampoule':
      return isAr ? 'أمبول' : 'Ampoule';
    case 'vial':
      return isAr ? 'فيال' : 'Vial';
    case 'suppository':
      return isAr ? 'لبوس' : 'Suppository';
    case 'sachet':
      return isAr ? 'أكياس' : 'Sachet';
    case 'patch':
      return isAr ? 'لاصقة' : 'Patch';
    default:
      return isAr ? 'غير معروف' : 'Unknown';
  }
}

String getQuantityFieldLabel(String? quantityUnit, {String locale = 'en'}) {
  final unit = getQuantityUnitLabel(quantityUnit, locale: locale);
  return locale == 'ar' ? 'الكمية الكلية ($unit)' : 'Total quantity ($unit)';
}

String getDoseQuantityFieldLabel(String? quantityUnit, {String locale = 'en'}) {
  final unit = getQuantityUnitLabel(quantityUnit, locale: locale);
  return locale == 'ar' ? 'كمية الجرعة ($unit)' : 'Quantity per dose ($unit)';
}

String formatQuantityWithUnit(
  int? quantity,
  String? quantityUnit, {
  String locale = 'en',
}) {
  final unit = getQuantityUnitLabel(quantityUnit, locale: locale);
  return '${quantity ?? 0} $unit';
}

String takeQuantityLabel(
  int? quantity,
  String? quantityUnit, {
  String locale = 'en',
}) {
  final value = formatQuantityWithUnit(quantity, quantityUnit, locale: locale);
  return locale == 'ar' ? 'خذ $value' : 'Take $value';
}

String remainingQuantityLabel(
  int? quantity,
  String? quantityUnit, {
  String locale = 'en',
}) {
  final value = formatQuantityWithUnit(quantity, quantityUnit, locale: locale);
  return locale == 'ar' ? 'المتبقي: $value' : 'Remaining: $value';
}
