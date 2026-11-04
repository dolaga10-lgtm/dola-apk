import 'dart:math' as math;

/// جزء أو قطعة من مكونات القطاع (حلق، ضلفة، سكينة، باكتة، محبس، إلخ)
class SectorPart {
  String id;
  String name; // اسم الجزء (مثل: حلق علوي/سفلي، سكينة، قائم ضلفة)
  String role; // الفئة: حلق | ضلفة | سكينة | إضافي | باكتة | مكمل | مخصص
  String dimensionBasis; // width | height | width_per_sash | fixed
  double offsetCm; // قيمة التخصيم أو الإضافة بالسنتيمتر (سالب للخصم، موجب للإضافة)
  int quantityPerWindow; // العدد المضاف لكل شباك
  bool multiplyBySashes; // هل يُضرب العدد في عدد الضلف؟

  SectorPart({
    required this.id,
    required this.name,
    required this.role,
    required this.dimensionBasis,
    required this.offsetCm,
    required this.quantityPerWindow,
    this.multiplyBySashes = false,
  });

  /// توافق مع أسماء الخصائص البديلة
  double get deductFromWidthCm => -offsetCm;
  double get deductFromHeightCm => -offsetCm;
  int get multiplier => quantityPerWindow;
  double get addPerSashCm => offsetCm;

  /// حساب طول القطعة الواحدة بالسنتيمتر بناءً على عرض وارتفاع الشباك وعدد الضلف
  double calculatePieceLength(double widthCm, double heightCm, int sashCount) {
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    double baseVal = 0.0;
    switch (dimensionBasis) {
      case 'width':
        baseVal = widthCm;
        break;
      case 'height':
        baseVal = heightCm;
        break;
      case 'width_per_sash':
        baseVal = widthCm / safeSashes;
        break;
      case 'fixed':
        baseVal = 0.0;
        break;
      default:
        baseVal = widthCm;
    }
    final double result = baseVal + offsetCm;
    return result > 0 ? double.parse(result.toStringAsFixed(2)) : 0.0;
  }

  /// حساب إجمالي عدد القطع المطلوبة لهذا الجزء
  int calculateTotalCount(int windowQuantity, int sashCount) {
    final int safeWindows = windowQuantity > 0 ? windowQuantity : 1;
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    final int perWindow = multiplyBySashes
        ? (quantityPerWindow * safeSashes)
        : quantityPerWindow;
    return perWindow * safeWindows;
  }

  int calculateTotalPieces(int sashCount) => calculateTotalCount(1, sashCount);

  String get basisArabicLabel {
    switch (dimensionBasis) {
      case 'width':
        return 'العرض الكلي (W)';
      case 'height':
        return 'الارتفاع الكلي (H)';
      case 'width_per_sash':
        return 'العرض ÷ عدد الضلف';
      case 'fixed':
        return 'طول ثابت (سم)';
      default:
        return 'العرض الكلي (W)';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'dimensionBasis': dimensionBasis,
        'offsetCm': offsetCm,
        'quantityPerWindow': quantityPerWindow,
        'multiplyBySashes': multiplyBySashes,
      };

  factory SectorPart.fromJson(Map<String, dynamic> json) => SectorPart(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        role: json['role']?.toString() ?? 'حلق',
        dimensionBasis: json['dimensionBasis']?.toString() ?? 'width',
        offsetCm: (json['offsetCm'] as num?)?.toDouble() ??
            (-(json['deductFromWidthCm'] as num? ?? 0.0).toDouble()),
        quantityPerWindow: (json['quantityPerWindow'] as num?)?.toInt() ??
            (json['multiplier'] as num?)?.toInt() ??
            1,
        multiplyBySashes: json['multiplyBySashes'] == true,
      );
}

/// ملف تعريف القطاع (Sector Profile)
class SectorProfile {
  String id;
  String name;
  String category; // جرار | مفصلي | مطبخ | ثابت | مخصص
  String companyGroup; // الشارقة | السعد PS | الدولية ماكسيم | ألوميل | فولكانو | فالف | uPVC المصري | uPVC المستورد | مطابخ | مخصص
  String systemType; // شباك جرار | باب جرار | شباك مفصلي | باب مفصلي | قلاب | مطبخ | مخصص
  int defaultSashCount;
  String? imagePath;
  double pricePerSquareMeter;
  double glassWidthDeductCm;
  double glassHeightDeductCm;
  bool isCustom;
  List<SectorPart> parts;

  SectorProfile({
    required this.id,
    required this.name,
    this.category = 'جرار',
    required this.companyGroup,
    required this.systemType,
    this.defaultSashCount = 2,
    this.imagePath,
    required this.pricePerSquareMeter,
    this.glassWidthDeductCm = 11.4,
    this.glassHeightDeductCm = 11.4,
    this.isCustom = false,
    required this.parts,
  });

  bool get isDoor => systemType.contains('باب');
  bool get isSliding => systemType.contains('جرار') || category.contains('جرار');
  bool get isHinged => systemType.contains('مفصلي') || systemType.contains('قلاب') || category.contains('مفصلي');

  double calculateSingleSashWidth(double widthCm, int sashCount) {
    for (final p in parts) {
      if (p.role == 'ضلفة' || p.role == 'درفة') {
        if (p.dimensionBasis == 'width_per_sash' || p.dimensionBasis == 'width') {
          return p.calculatePieceLength(widthCm, 0, sashCount);
        }
      }
    }
    final int safeSashes = sashCount > 0 ? sashCount : 1;
    return (widthCm / safeSashes) + (isSliding ? 1.5 : -4.8);
  }

  double calculateSingleSashHeight(double heightCm, int sashCount) {
    for (final p in parts) {
      if ((p.role == 'ضلفة' || p.role == 'درفة') && p.dimensionBasis == 'height') {
        return p.calculatePieceLength(0, heightCm, sashCount);
      }
    }
    return math.max(0.0, heightCm - (isSliding ? 8.2 : 4.8));
  }

  double calculateGlassWidthCm(double widthCm, int sashCount) {
    final double sashW = calculateSingleSashWidth(widthCm, sashCount);
    return math.max(0.0, double.parse((sashW - glassWidthDeductCm).toStringAsFixed(2)));
  }

  double calculateGlassHeightCm(double heightCm, int sashCount) {
    final double sashH = calculateSingleSashHeight(heightCm, sashCount);
    return math.max(0.0, double.parse((sashH - glassHeightDeductCm).toStringAsFixed(2)));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'companyGroup': companyGroup,
        'systemType': systemType,
        'defaultSashCount': defaultSashCount,
        'imagePath': imagePath,
        'pricePerSquareMeter': pricePerSquareMeter,
        'glassWidthDeductCm': glassWidthDeductCm,
        'glassHeightDeductCm': glassHeightDeductCm,
        'isCustom': isCustom,
        'parts': parts.map((e) => e.toJson()).toList(),
      };

  factory SectorProfile.fromJson(Map<String, dynamic> json) => SectorProfile(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        category: json['category'] ?? 'جرار',
        companyGroup: json['companyGroup'] ?? json['category'] ?? 'عام',
        systemType: json['systemType'] ?? json['category'] ?? 'شباك جرار',
        defaultSashCount: json['defaultSashCount'] ?? 2,
        imagePath: json['imagePath'],
        pricePerSquareMeter: (json['pricePerSquareMeter'] as num?)?.toDouble() ?? 2500.0,
        glassWidthDeductCm: (json['glassWidthDeductCm'] as num?)?.toDouble() ?? 11.4,
        glassHeightDeductCm: (json['glassHeightDeductCm'] as num?)?.toDouble() ?? 11.4,
        isCustom: json['isCustom'] ?? false,
        parts: (json['parts'] as List<dynamic>?)
                ?.map((e) => SectorPart.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

/// نوع الزجاج في قائمة التسعير
class GlassTypeItem {
  String id;
  String name;
  double pricePerSquareMeter;
  String thickness;
  String color;

  GlassTypeItem({
    required this.id,
    required this.name,
    required this.pricePerSquareMeter,
    this.thickness = '6 مم',
    this.color = 'شفاف',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pricePerSquareMeter': pricePerSquareMeter,
        'thickness': thickness,
        'color': color,
      };

  factory GlassTypeItem.fromJson(Map<String, dynamic> json) => GlassTypeItem(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        pricePerSquareMeter: (json['pricePerSquareMeter'] as num?)?.toDouble() ?? 450.0,
        thickness: json['thickness'] ?? '6 مم',
        color: json['color'] ?? 'شفاف',
      );
}

/// إعدادات التسعير والورشة
class PricingSettings {
  double doubleSpacerPricePerMeter;
  double georgianBarPricePerMeter;
  double defaultStockBarLengthCm;
  double defaultSawKerfMm;
  bool enforceMinimumOneSquareMeter;

  String companyName;
  String companySubtitle;
  String companyPhones;
  String companyAddress;
  String termsAndConditions;

  PricingSettings({
    this.doubleSpacerPricePerMeter = 45.0,
    this.georgianBarPricePerMeter = 85.0,
    this.defaultStockBarLengthCm = 600.0,
    this.defaultSawKerfMm = 4.0,
    this.enforceMinimumOneSquareMeter = false,
    this.companyName = 'شركة الحافظ',
    this.companySubtitle =
        'للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية (خبرة منذ 1980)',
    this.companyPhones = '01000000000 - 01200000000',
    this.companyAddress = 'جمهورية مصر العربية',
    this.termsAndConditions =
        'الأسعار شاملة التوريد والتركيب والضمان المعتمد من شركة الحافظ.',
  });

  Map<String, dynamic> toJson() => {
        'doubleSpacerPricePerMeter': doubleSpacerPricePerMeter,
        'georgianBarPricePerMeter': georgianBarPricePerMeter,
        'defaultStockBarLengthCm': defaultStockBarLengthCm,
        'defaultSawKerfMm': defaultSawKerfMm,
        'enforceMinimumOneSquareMeter': enforceMinimumOneSquareMeter,
        'companyName': companyName,
        'companySubtitle': companySubtitle,
        'companyPhones': companyPhones,
        'companyAddress': companyAddress,
        'termsAndConditions': termsAndConditions,
      };

  factory PricingSettings.fromJson(Map<String, dynamic> json) => PricingSettings(
        doubleSpacerPricePerMeter:
            (json['doubleSpacerPricePerMeter'] as num?)?.toDouble() ?? 45.0,
        georgianBarPricePerMeter:
            (json['georgianBarPricePerMeter'] as num?)?.toDouble() ?? 85.0,
        defaultStockBarLengthCm:
            (json['defaultStockBarLengthCm'] as num?)?.toDouble() ?? 600.0,
        defaultSawKerfMm: (json['defaultSawKerfMm'] as num?)?.toDouble() ?? 4.0,
        enforceMinimumOneSquareMeter: json['enforceMinimumOneSquareMeter'] ?? false,
        companyName: json['companyName'] ?? 'شركة الحافظ',
        companySubtitle: json['companySubtitle'] ??
            'للمطابخ الألومنيوم والخشب وجميع أعمال الأخشاب والواجهات الزجاجية (خبرة منذ 1980)',
        companyPhones: json['companyPhones'] ?? '01000000000 - 01200000000',
        companyAddress: json['companyAddress'] ?? 'جمهورية مصر العربية',
        termsAndConditions: json['termsAndConditions'] ??
            'الأسعار شاملة التوريد والتركيب والضمان المعتمد من شركة الحافظ.',
      );
}

/// عنصر شباك أو باب مقايسة العميل
class ClientWindowItem {
  String id;
  String label;
  String unitType;
  String openType;
  String barType;
  String openDirection;
  String sectorId;
  String sectorName;
  double sectorPricePerM2;
  String sectorColor;
  double widthCm;
  double heightCm;
  int quantity;
  int sashCount;

  // الخصائص المعمارية المتقدمة (الثوابت والشفاط)
  bool hasTopFixed;
  double topFixedHeightCm;
  bool hasBottomFixed;
  double bottomFixedHeightCm;
  bool hasRightFixed;
  double rightFixedWidthCm;
  bool hasLeftFixed;
  double leftFixedWidthCm;
  bool hasExhaustFan;
  String exhaustFanShape;
  double exhaustFanDiameterCm;
  String exhaustFanPosition;

  // إعدادات الزجاج
  bool hasGlass;
  bool isDoubleGlass;
  String? glass1Id;
  String glass1Name;
  double glass1PricePerM2;
  String? glass2Id;
  String glass2Name;
  double glass2PricePerM2;
  double spacerPricePerMeter;

  // إعدادات الجورجيا
  bool hasGeorgianBars;
  double georgianMetersPerWindow;
  double georgianPricePerMeter;

  ClientWindowItem({
    required this.id,
    required this.label,
    this.unitType = 'شباك',
    this.openType = 'جرار',
    this.barType = 'بار عادي',
    this.openDirection = 'يمين للداخل',
    required this.sectorId,
    required this.sectorName,
    required this.sectorPricePerM2,
    this.sectorColor = 'بيج',
    required this.widthCm,
    required this.heightCm,
    this.quantity = 1,
    this.sashCount = 2,
    this.hasTopFixed = false,
    this.topFixedHeightCm = 40.0,
    this.hasBottomFixed = false,
    this.bottomFixedHeightCm = 40.0,
    this.hasRightFixed = false,
    this.rightFixedWidthCm = 40.0,
    this.hasLeftFixed = false,
    this.leftFixedWidthCm = 40.0,
    this.hasExhaustFan = false,
    this.exhaustFanShape = 'دائري',
    this.exhaustFanDiameterCm = 25.0,
    this.exhaustFanPosition = 'في الثابت العلوي',
    this.hasGlass = true,
    this.isDoubleGlass = false,
    this.glass1Id,
    this.glass1Name = 'زجاج شفاف 6 مم',
    this.glass1PricePerM2 = 450.0,
    this.glass2Id,
    this.glass2Name = 'زجاج عاكس 6 مم',
    this.glass2PricePerM2 = 550.0,
    this.spacerPricePerMeter = 45.0,
    this.hasGeorgianBars = false,
    this.georgianMetersPerWindow = 0.0,
    this.georgianPricePerMeter = 85.0,
  });

  double singleWindowAreaM2({bool minOneM2 = false}) {
    final double rawArea = (widthCm / 100.0) * (heightCm / 100.0);
    if (minOneM2 && rawArea < 1.0) {
      return 1.0;
    }
    return rawArea;
  }

  double totalAreaM2({bool minOneM2 = false}) =>
      singleWindowAreaM2(minOneM2: minOneM2) * quantity;

  double totalSpacerMeters(SectorProfile? sector) {
    if (!hasGlass || !isDoubleGlass) return 0.0;
    final double gwCm = sector != null
        ? sector.calculateGlassWidthCm(widthCm, sashCount)
        : math.max(0.0, (widthCm / (sashCount > 0 ? sashCount : 1)) - 10.0);
    final double ghCm = sector != null
        ? sector.calculateGlassHeightCm(heightCm, sashCount)
        : math.max(0.0, heightCm - 18.0);
    final double singleSashPerimeterM = 2.0 * ((gwCm + ghCm) / 100.0);
    return singleSashPerimeterM * (sashCount > 0 ? sashCount : 1) * quantity;
  }

  double calculateSectorCost({bool minOneM2 = false}) =>
      totalAreaM2(minOneM2: minOneM2) * sectorPricePerM2;

  double calculateGlassAndSpacerCost(SectorProfile? sector, {bool minOneM2 = false}) {
    if (!hasGlass) return 0.0;
    final double area = totalAreaM2(minOneM2: minOneM2);
    if (!isDoubleGlass) {
      return area * glass1PricePerM2;
    } else {
      final double panesCost = area * (glass1PricePerM2 + glass2PricePerM2);
      final double spacerCost = totalSpacerMeters(sector) * spacerPricePerMeter;
      return panesCost + spacerCost;
    }
  }

  double calculateGeorgianCost() {
    if (!hasGeorgianBars || georgianMetersPerWindow <= 0) return 0.0;
    return georgianMetersPerWindow * quantity * georgianPricePerMeter;
  }

  double calculateTotalCost(SectorProfile? sector, {bool minOneM2 = false}) {
    return calculateSectorCost(minOneM2: minOneM2) +
        calculateGlassAndSpacerCost(sector, minOneM2: minOneM2) +
        calculateGeorgianCost();
  }

  String get glassSummaryText {
    if (!hasGlass) return 'بدون زجاج';
    if (!isDoubleGlass) {
      return 'سنجل: $glass1Name';
    }
    return 'دبل: ($glass1Name + $glass2Name + سبيسر)';
  }

  String get configurationSummary {
    final List<String> list = [];
    list.add('$unitType $openType $sashCount درفة');
    if (hasTopFixed) list.add('ثابت علوي ($topFixedHeightCm سم)');
    if (hasBottomFixed) list.add('ثابت سفلي ($bottomFixedHeightCm سم)');
    if (hasRightFixed) list.add('ثابت يمين ($rightFixedWidthCm سم)');
    if (hasLeftFixed) list.add('ثابت شمال ($leftFixedWidthCm سم)');
    if (hasExhaustFan) list.add('فتحة شفاط $exhaustFanShape ($exhaustFanDiameterCm سم)');
    return list.join(' • ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'unitType': unitType,
        'openType': openType,
        'barType': barType,
        'openDirection': openDirection,
        'sectorId': sectorId,
        'sectorName': sectorName,
        'sectorPricePerM2': sectorPricePerM2,
        'sectorColor': sectorColor,
        'widthCm': widthCm,
        'heightCm': heightCm,
        'quantity': quantity,
        'sashCount': sashCount,
        'hasTopFixed': hasTopFixed,
        'topFixedHeightCm': topFixedHeightCm,
        'hasBottomFixed': hasBottomFixed,
        'bottomFixedHeightCm': bottomFixedHeightCm,
        'hasRightFixed': hasRightFixed,
        'rightFixedWidthCm': rightFixedWidthCm,
        'hasLeftFixed': hasLeftFixed,
        'leftFixedWidthCm': leftFixedWidthCm,
        'hasExhaustFan': hasExhaustFan,
        'exhaustFanShape': exhaustFanShape,
        'exhaustFanDiameterCm': exhaustFanDiameterCm,
        'exhaustFanPosition': exhaustFanPosition,
        'hasGlass': hasGlass,
        'isDoubleGlass': isDoubleGlass,
        'glass1Id': glass1Id,
        'glass1Name': glass1Name,
        'glass1PricePerM2': glass1PricePerM2,
        'glass2Id': glass2Id,
        'glass2Name': glass2Name,
        'glass2PricePerM2': glass2PricePerM2,
        'spacerPricePerMeter': spacerPricePerMeter,
        'hasGeorgianBars': hasGeorgianBars,
        'georgianMetersPerWindow': georgianMetersPerWindow,
        'georgianPricePerMeter': georgianPricePerMeter,
      };

  factory ClientWindowItem.fromJson(Map<String, dynamic> json) => ClientWindowItem(
        id: json['id'] ?? '',
        label: json['label'] ?? 'شباك',
        unitType: json['unitType'] ?? 'شباك',
        openType: json['openType'] ?? 'جرار',
        barType: json['barType'] ?? 'بار عادي',
        openDirection: json['openDirection'] ?? 'يمين للداخل',
        sectorId: json['sectorId'] ?? '',
        sectorName: json['sectorName'] ?? '',
        sectorPricePerM2: (json['sectorPricePerM2'] as num?)?.toDouble() ?? 2500.0,
        sectorColor: json['sectorColor']?.toString() ?? 'بيج',
        widthCm: (json['widthCm'] as num?)?.toDouble() ?? 100.0,
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? 100.0,
        quantity: json['quantity'] ?? 1,
        sashCount: json['sashCount'] ?? 2,
        hasTopFixed: json['hasTopFixed'] ?? false,
        topFixedHeightCm: (json['topFixedHeightCm'] as num?)?.toDouble() ?? 40.0,
        hasBottomFixed: json['hasBottomFixed'] ?? false,
        bottomFixedHeightCm: (json['bottomFixedHeightCm'] as num?)?.toDouble() ?? 40.0,
        hasRightFixed: json['hasRightFixed'] ?? false,
        rightFixedWidthCm: (json['rightFixedWidthCm'] as num?)?.toDouble() ?? 40.0,
        hasLeftFixed: json['hasLeftFixed'] ?? false,
        leftFixedWidthCm: (json['leftFixedWidthCm'] as num?)?.toDouble() ?? 40.0,
        hasExhaustFan: json['hasExhaustFan'] ?? false,
        exhaustFanShape: json['exhaustFanShape'] ?? 'دائري',
        exhaustFanDiameterCm: (json['exhaustFanDiameterCm'] as num?)?.toDouble() ?? 25.0,
        exhaustFanPosition: json['exhaustFanPosition'] ?? 'في الثابت العلوي',
        hasGlass: json['hasGlass'] ?? true,
        isDoubleGlass: json['isDoubleGlass'] ?? false,
        glass1Id: json['glass1Id'],
        glass1Name: json['glass1Name'] ?? 'زجاج شفاف 6 مم',
        glass1PricePerM2: (json['glass1PricePerM2'] as num?)?.toDouble() ?? 450.0,
        glass2Id: json['glass2Id'],
        glass2Name: json['glass2Name'] ?? 'زجاج عاكس 6 مم',
        glass2PricePerM2: (json['glass2PricePerM2'] as num?)?.toDouble() ?? 550.0,
        spacerPricePerMeter: (json['spacerPricePerMeter'] as num?)?.toDouble() ?? 45.0,
        hasGeorgianBars: json['hasGeorgianBars'] ?? false,
        georgianMetersPerWindow: (json['georgianMetersPerWindow'] as num?)?.toDouble() ?? 0.0,
        georgianPricePerMeter: (json['georgianPricePerMeter'] as num?)?.toDouble() ?? 85.0,
      );
}

/// سجل مقايسة العميل
class ClientRecord {
  String id;
  String clientName;
  String clientPhone;
  String clientAddress;
  String createdAt;
  String notes;
  double discountAmount;
  double depositAmount;
  double archCost;
  List<ClientWindowItem> items;

  ClientRecord({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    required this.createdAt,
    this.notes = '',
    this.discountAmount = 0.0,
    this.depositAmount = 0.0,
    this.archCost = 0.0,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'clientAddress': clientAddress,
        'createdAt': createdAt,
        'notes': notes,
        'discountAmount': discountAmount,
        'depositAmount': depositAmount,
        'archCost': archCost,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory ClientRecord.fromJson(Map<String, dynamic> json) => ClientRecord(
        id: json['id'] ?? '',
        clientName: json['clientName'] ?? '',
        clientPhone: json['clientPhone'] ?? '',
        clientAddress: json['clientAddress'] ?? '',
        createdAt: json['createdAt'] ?? '',
        notes: json['notes'] ?? '',
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
        depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
        archCost: (json['archCost'] as num?)?.toDouble() ?? 0.0,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ClientWindowItem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );
}

/// نموذج خطة تقطيع العود 600 سم
class BarCutPlan {
  int barNumber;
  int get barIndex => barNumber;
  set barIndex(int v) => barNumber = v;

  double barLengthCm;
  double kerfMm;

  List<double> cutsCm;
  List<double> get cutPiecesCm => cutsCm;
  set cutPiecesCm(List<double> v) => cutsCm = v;

  double usedLengthCm;
  double wasteLengthCm;
  double wastePercentage;

  BarCutPlan({
    int? barNumber,
    int? barIndex,
    this.barLengthCm = 600.0,
    this.kerfMm = 4.0,
    List<double>? cutsCm,
    List<double>? cutPiecesCm,
    required this.usedLengthCm,
    required this.wasteLengthCm,
    required this.wastePercentage,
  })  : barNumber = barNumber ?? barIndex ?? 1,
        cutsCm = cutsCm ?? cutPiecesCm ?? [];
}
