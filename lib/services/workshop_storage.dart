import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workshop_models.dart';

class WorkshopStorage extends ChangeNotifier {
  static const String _kSectorsKey = 'hafez_sw_sectors_v7';
  static const String _kGlassesKey = 'hafez_sw_glasses_v5';
  static const String _kSettingsKey = 'hafez_sw_pricing_settings_v5';
  static const String _kClientsKey = 'hafez_sw_clients_records_v5';

  List<SectorProfile> sectors = [];
  List<GlassTypeItem> glassTypes = [];
  PricingSettings pricingSettings = PricingSettings();
  List<ClientRecord> clients = [];
  bool isLoaded = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final String? sectorsRaw = prefs.getString(_kSectorsKey);
    if (sectorsRaw != null && sectorsRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(sectorsRaw);
        sectors = list
            .map((e) => SectorProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        sectors = _allStandardSectors();
      }
    } else {
      sectors = _allStandardSectors();
    }

    final String? glassesRaw = prefs.getString(_kGlassesKey);
    if (glassesRaw != null && glassesRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(glassesRaw);
        glassTypes = list
            .map((e) => GlassTypeItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        glassTypes = _defaultGlassTypes();
      }
    } else {
      glassTypes = _defaultGlassTypes();
    }

    final String? settingsRaw = prefs.getString(_kSettingsKey);
    if (settingsRaw != null && settingsRaw.isNotEmpty) {
      try {
        pricingSettings = PricingSettings.fromJson(
            Map<String, dynamic>.from(jsonDecode(settingsRaw)));
      } catch (_) {
        pricingSettings = PricingSettings();
      }
    }

    final String? clientsRaw = prefs.getString(_kClientsKey);
    if (clientsRaw != null && clientsRaw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(clientsRaw);
        clients = list
            .map((e) => ClientRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        clients = [];
      }
    }

    isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kSectorsKey, jsonEncode(sectors.map((e) => e.toJson()).toList()));
    await prefs.setString(
        _kGlassesKey, jsonEncode(glassTypes.map((e) => e.toJson()).toList()));
    await prefs.setString(_kSettingsKey, jsonEncode(pricingSettings.toJson()));
    await prefs.setString(
        _kClientsKey, jsonEncode(clients.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  SectorProfile? getSectorById(String id) {
    for (final s in sectors) {
      if (s.id == id) return s;
    }
    return sectors.isNotEmpty ? sectors.first : null;
  }

  Future<void> addOrUpdateSector(SectorProfile sector) async {
    final idx = sectors.indexWhere((e) => e.id == sector.id);
    if (idx >= 0) {
      sectors[idx] = sector;
    } else {
      sectors.insert(0, sector);
    }
    await _saveAll();
  }

  Future<void> deleteSector(String id) async {
    sectors.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> updateSectorPrice(String sectorId, double newPrice) async {
    final idx = sectors.indexWhere((e) => e.id == sectorId);
    if (idx >= 0) {
      sectors[idx].pricePerSquareMeter = newPrice;
      await _saveAll();
    }
  }

  Future<void> addOrUpdateGlassType(GlassTypeItem item) async {
    final idx = glassTypes.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      glassTypes[idx] = item;
    } else {
      glassTypes.add(item);
    }
    await _saveAll();
  }

  Future<void> deleteGlassType(String id) async {
    glassTypes.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  Future<void> updatePricingSettings(PricingSettings newSettings) async {
    pricingSettings = newSettings;
    await _saveAll();
  }

  Future<void> saveClientRecord(ClientRecord record) async {
    final idx = clients.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      clients[idx] = record;
    } else {
      clients.insert(0, record);
    }
    await _saveAll();
  }

  Future<void> deleteClientRecord(String clientId) async {
    clients.removeWhere((e) => e.id == clientId);
    await _saveAll();
  }

  static List<BarCutPlan> optimize1DBars({
    required List<double> requiredPiecesCm,
    double stockLengthCm = 600.0,
    double sawKerfMm = 4.0,
  }) {
    final double kerfCm = sawKerfMm / 10.0;
    final List<double> sorted = requiredPiecesCm
        .where((p) => p > 0 && p <= stockLengthCm)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final List<List<double>> bins = [];
    final List<double> binRemaining = [];

    for (final piece in sorted) {
      bool placed = false;
      for (int i = 0; i < bins.length; i++) {
        final double needed = piece + (bins[i].isEmpty ? 0.0 : kerfCm);
        if (binRemaining[i] >= needed - 1e-6) {
          bins[i].add(piece);
          binRemaining[i] = math.max(0.0, binRemaining[i] - needed);
          placed = true;
          break;
        }
      }
      if (!placed) {
        bins.add([piece]);
        binRemaining.add(math.max(0.0, stockLengthCm - piece));
      }
    }

    final List<BarCutPlan> plans = [];
    for (int i = 0; i < bins.length; i++) {
      final double waste = double.parse(binRemaining[i].toStringAsFixed(2));
      final double used =
          double.parse((stockLengthCm - waste).toStringAsFixed(2));
      plans.add(BarCutPlan(
        barNumber: i + 1,
        barLengthCm: stockLengthCm,
        cutsCm: bins[i],
        usedLengthCm: used,
        wasteLengthCm: waste,
        wastePercentage: stockLengthCm > 0 ? (waste / stockLengthCm) * 100 : 0.0,
      ));
    }
    return plans;
  }

  /// جميع قطاعات تطبيق الورشة الذكية الأصلية (الـ 25 قطاعاً بجميع الشركات + قطاعات uPVC والمطابخ)
  List<SectorProfile> _allStandardSectors() {
    return [
      // 1. قطاعات الشارقة / مركز الماكينات (sh)
      _createSlidingSector('sec_jumbo_100', 'جامبو 100 جرار (Jumbo 100)', 'الشارقة', 2650, 11.4, 11.4, 1.5, -8.2),
      _createSlidingSector('sec_tango_60', 'تانجو 60 جرار (Tango 60)', 'الشارقة', 2350, 10.2, 10.2, 1.2, -7.5),
      _createSlidingSector('sec_tendu_120', 'تندو 120 جرار (TenDu 120)', 'الشارقة', 2850, 12.0, 12.0, 1.8, -9.0),
      _createSlidingSector('sec_tembo_84', 'تيمبو 84 جرار (TemBo 84)', 'الشارقة', 2450, 10.5, 10.5, 1.4, -8.0),
      _createHingedSector('sec_sonata_45', 'سوناتا 45 مفصلي (Sonata 45)', 'الشارقة', 2400, 9.5, 9.5, -4.8, -4.8),
      _createHingedSector('sec_nano_50', 'نانو 50 مفصلي (Nano 50)', 'الشارقة', 2100, 9.2, 9.2, -4.2, -4.2),

      // 2. قطاعات السعد PS
      _createSlidingSector('sec_ps_9600', 'بي إس 9600 جرار كبير (PS 9600)', 'السعد PS', 2300, 10.6, 10.6, -0.5, -6.5),
      _createSlidingSector('sec_ps_6600', 'بي إس 6600 جرار وسط (PS 6600)', 'السعد PS', 1950, 8.8, 8.8, -0.4, -5.8),
      _createSlidingSector('sec_ps_5600', 'بي إس 5600 جرار صغير (PS 5600)', 'السعد PS', 1850, 8.2, 8.2, -0.3, -5.4),
      _createHingedSector('sec_ps_4800', 'بي إس 4800 مفصلي (PS 4800)', 'السعد PS', 1900, 8.5, 8.5, -4.0, -4.0),

      // 3. قطاعات الدولية ماكسيم (Maxim)
      _createSlidingSector('sec_maxim_e105', 'ماكسيم 105 جرار (Maxim E105)', 'الدولية ماكسيم', 2400, 10.4, 10.4, 1.2, -7.8),
      _createSlidingSector('sec_maxim_e777', 'ماكسيم 777 جرار عريض (Maxim E777)', 'الدولية ماكسيم', 2700, 11.5, 11.5, 1.6, -8.5),
      _createHingedSector('sec_maxim_e47', 'إيكونومي 47 مفصلي (Maxim E47)', 'الدولية ماكسيم', 2500, 9.8, 9.8, -4.6, -4.6),
      _createHingedSector('sec_maxim_e37', 'إيكونومي 37 مفصلي (Maxim E37)', 'الدولية ماكسيم', 2150, 8.6, 8.6, -4.0, -4.0),

      // 4. قطاعات ألوميل اليوناني (AluMil)
      _createSlidingSector('sec_alumil_m9200', 'ألوميل M9200 جرار عازل', 'ألوميل اليوناني', 3400, 12.5, 12.5, 2.0, -9.5),
      _createSlidingSector('sec_alumil_m12000', 'ألوميل M12000 جرار جامبو', 'ألوميل اليوناني', 3600, 13.0, 13.0, 2.2, -10.0),
      _createSlidingSector('sec_alumil_m900', 'ألوميل M900 جرار خفيف', 'ألوميل اليوناني', 2900, 10.8, 10.8, 1.4, -8.0),
      _createHingedSector('sec_alumil_m9400', 'ألوميل M9400 مفصلي عازل حرارياً', 'ألوميل اليوناني', 3200, 11.0, 11.0, -5.2, -5.2),
      _createHingedSector('sec_alumil_m940', 'ألوميل M940 مفصلي خفيف', 'ألوميل اليوناني', 2800, 9.6, 9.6, -4.5, -4.5),

      // 5. قطاعات فولكانو (Volcano)
      _createSlidingSector('sec_volcano_v120', 'فولكانو V120 جرار ثقيل', 'فولكانو', 3100, 12.0, 12.0, 1.8, -9.0),
      _createSlidingSector('sec_volcano_v70', 'فولكانو V70 جرار وسط', 'فولكانو', 2600, 10.5, 10.5, 1.4, -7.8),
      _createHingedSector('sec_volcano_v44', 'فولكانو V44 مفصلي', 'فولكانو', 2700, 10.0, 10.0, -4.8, -4.8),

      // 6. قطاعات فالف القباري (Valve)
      _createSlidingSector('sec_valve_v170', 'فالف V170 جرار بانوراما', 'فالف القباري', 3300, 12.8, 12.8, 2.0, -9.8),
      _createSlidingSector('sec_valve_v140', 'فالف V140 جرار 3 سكة', 'فالف القباري', 2800, 11.2, 11.2, 1.5, -8.4),
      _createHingedSector('sec_valve_mv100', 'فالف MV100 مفصلي عازل', 'فالف القباري', 2950, 10.5, 10.5, -5.0, -5.0),

      // 7. قطاعات الـ uPVC المصري (إيمابن Emapen)
      _createSlidingSector('sec_emapen_sliding_2', 'إيمابن (Emapen) شباك جرار 2 ضلفة مع سلك', 'uPVC المصري (إيمابن)', 2800, 13.0, 13.0, 2.0, -10.0),
      _createSlidingSector('sec_emapen_sliding_4', 'إيمابن (Emapen) شباك جرار 4 ضلف', 'uPVC المصري (إيمابن)', 2950, 13.0, 13.0, 1.5, -10.0),
      _createHingedSector('sec_emapen_hinged_window', 'إيمابن (Emapen) شباك مفصلي سنجل ودبل', 'uPVC المصري (إيمابن)', 2900, 11.8, 11.8, -5.2, -5.2),
      _createHingedSector('sec_emapen_hinged_door', 'إيمابن (Emapen) باب مفصلي مع عتبة ألومنيوم', 'uPVC المصري (إيمابن)', 3200, 12.5, 12.5, -5.5, -5.5),
      _createHingedSector('sec_emapen_tilt', 'إيمابن (Emapen) قلاب حمامات ومطابخ', 'uPVC المصري (إيمابن)', 2700, 11.0, 11.0, -5.0, -5.0),

      // 8. قطاعات الـ uPVC المستورد (تركي وألماني)
      _createSlidingSector('sec_wintech_sliding', 'وينتك (Wintech تركي) شباك جرار عازل صوت وحرارة', 'uPVC المستورد', 3500, 13.5, 13.5, 2.0, -10.2),
      _createHingedSector('sec_wintech_hinged', 'وينتك (Wintech تركي) شباك وباب مفصلي كاوتش مزدوج', 'uPVC المستورد', 3600, 12.2, 12.2, -5.5, -5.5),
      _createSlidingSector('sec_kompen_sliding', 'كومبن (Kompen تركي) شباك جرار 2 ضلفة', 'uPVC المستورد', 3400, 13.2, 13.2, 1.8, -10.0),
      _createHingedSector('sec_kompen_hinged', 'كومبن (Kompen تركي) مفصلي عازل', 'uPVC المستورد', 3450, 12.0, 12.0, -5.4, -5.4),
      _createSlidingSector('sec_degro_sliding', 'ديجرو (Degro ألماني/تركي) جرار ثقيل عازل', 'uPVC المستورد', 3700, 14.0, 14.0, 2.2, -10.5),
      _createHingedSector('sec_pimapen_hinged', 'بيمابن (Pimapen تركي) شباك مفصلي وسنجل/دبل', 'uPVC المستورد', 3550, 12.5, 12.5, -5.6, -5.6),

      // 9. الواجهات والمطابخ الألومنيوم
      SectorProfile(
        id: 'sec_curtain_wall_50',
        name: 'واجهات زجاجية كورتن وول (Curtain Wall 50)',
        companyGroup: 'واجهات زجاجية',
        systemType: 'ثابت',
        defaultSashCount: 1,
        pricePerSquareMeter: 4200.0,
        glassWidthDeductCm: 2.5,
        glassHeightDeductCm: 2.5,
        isCustom: false,
        parts: [
          SectorPart(id: 'cw_p1', name: 'قائم رئيسي (Mullion)', role: 'حلق', dimensionBasis: 'height', deductFromWidthCm: 0, deductFromHeightCm: 0, multiplier: 2),
          SectorPart(id: 'cw_p2', name: 'عارضة أفقية (Transom)', role: 'حلق', dimensionBasis: 'width', deductFromWidthCm: 5.0, deductFromHeightCm: 0, multiplier: 2),
          SectorPart(id: 'cw_p3', name: 'غطاء خارجي كبس (Pressure Plate)', role: 'باكتة', dimensionBasis: 'perimeter', deductFromWidthCm: 0, deductFromHeightCm: 0, multiplier: 1),
        ],
      ),
      SectorProfile(
        id: 'sec_kitchen_1040',
        name: 'مطابخ ألومنيوم قطاع 10×40 (علب شاسيه)',
        companyGroup: 'مطابخ ألومنيوم',
        systemType: 'مطبخ',
        defaultSashCount: 2,
        pricePerSquareMeter: 3800.0,
        glassWidthDeductCm: 4.5,
        glassHeightDeductCm: 4.5,
        isCustom: false,
        parts: [
          SectorPart(id: 'k1', name: 'علبة شاسيه رئيسية (عرض)', role: 'حلق', dimensionBasis: 'width', deductFromWidthCm: 0, deductFromHeightCm: 0, multiplier: 4),
          SectorPart(id: 'k2', name: 'علبة شاسيه قائمة (عمق/ارتفاع)', role: 'حلق', dimensionBasis: 'height', deductFromWidthCm: 0, deductFromHeightCm: 0, multiplier: 4),
          SectorPart(id: 'k3', name: 'ضلفة مطبخ فايبر/كلادينج (عرض)', role: 'ضلفة', dimensionBasis: 'width_per_sash', deductFromWidthCm: 0.6, deductFromHeightCm: 0, multiplier: 2),
          SectorPart(id: 'k4', name: 'ضلفة مطبخ فايبر/كلادينج (ارتفاع)', role: 'ضلفة', dimensionBasis: 'height', deductFromWidthCm: 0, deductFromHeightCm: 0.6, multiplier: 2),
          SectorPart(id: 'k5', name: 'قاطع رف ألومنيوم 2.5×2.5', role: 'مكمل', dimensionBasis: 'width', deductFromWidthCm: 8.0, deductFromHeightCm: 0, multiplier: 2),
          SectorPart(id: 'k6', name: 'مقبض بلت إن (مقطع مقبض)', role: 'مكمل', dimensionBasis: 'width_per_sash', deductFromWidthCm: 0.6, deductFromHeightCm: 0, multiplier: 1),
        ],
      ),
      SectorProfile(
        id: 'sec_kitchen_2525',
        name: 'مطابخ ألومنيوم قطاع 2.5×2.5 (كلاسيك)',
        companyGroup: 'مطابخ ألومنيوم',
        systemType: 'مطبخ',
        defaultSashCount: 2,
        pricePerSquareMeter: 3300.0,
        glassWidthDeductCm: 3.5,
        glassHeightDeductCm: 3.5,
        isCustom: false,
        parts: [
          SectorPart(id: 'k7', name: 'علبة 2.5×2.5 (عرض الوحدة)', role: 'حلق', dimensionBasis: 'width', deductFromWidthCm: 0, deductFromHeightCm: 0, multiplier: 4),
          SectorPart(id: 'k8', name: 'علبة 2.5×2.5 (ارتفاع الوحدة)', role: 'حلق', dimensionBasis: 'height', deductFromWidthCm: 0, deductFromHeightCm: 0, multiplier: 4),
          SectorPart(id: 'k9', name: 'ضلفة مطبخ شطف 45 درجة (عرض)', role: 'ضلفة', dimensionBasis: 'width_per_sash', deductFromWidthCm: 0.5, deductFromHeightCm: 0, multiplier: 2),
          SectorPart(id: 'k10', name: 'ضلفة مطبخ شطف 45 درجة (ارتفاع)', role: 'ضلفة', dimensionBasis: 'height', deductFromWidthCm: 0, deductFromHeightCm: 0.5, multiplier: 2),
        ],
      ),
    ];
  }

  List<GlassTypeItem> _defaultGlassTypes() {
    return [
      GlassTypeItem(id: 'g_clear_6', name: 'زجاج شفاف 6 مم', pricePerSquareMeter: 450.0),
      GlassTypeItem(id: 'g_reflective_6_brown', name: 'زجاج عاكس بني 6 مم', pricePerSquareMeter: 600.0),
      GlassTypeItem(id: 'g_reflective_6_blue', name: 'زجاج عاكس أزرق 6 مم', pricePerSquareMeter: 620.0),
      GlassTypeItem(id: 'g_reflective_6_honey', name: 'زجاج عاكس عسلي 6 مم', pricePerSquareMeter: 600.0),
      GlassTypeItem(id: 'g_frosted_6', name: 'زجاج مصنفر / كريستال 6 مم', pricePerSquareMeter: 530.0),
      GlassTypeItem(id: 'g_tempered_10', name: 'زجاج سيكوريت 10 مم (واجهات وأبواب)', pricePerSquareMeter: 1200.0),
      GlassTypeItem(id: 'g_clear_4', name: 'زجاج شفاف 4 مم', pricePerSquareMeter: 350.0),
    ];
  }
}
