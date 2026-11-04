import 'package:flutter/material.dart';
import '../models/workshop_models.dart';
import '../services/workshop_storage.dart';

class PricingSettingsScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const PricingSettingsScreen({super.key, required this.storage});

  @override
  State<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends State<PricingSettingsScreen> {
  late TextEditingController _spacerPriceCtrl;
  late TextEditingController _georgianPriceCtrl;
  late TextEditingController _barLenCtrl;
  late TextEditingController _kerfCtrl;
  bool _minOneM2 = false;

  @override
  void initState() {
    super.initState();
    final s = widget.storage.pricingSettings;
    _spacerPriceCtrl =
        TextEditingController(text: s.doubleSpacerPricePerMeter.toString());
    _georgianPriceCtrl =
        TextEditingController(text: s.georgianBarPricePerMeter.toString());
    _barLenCtrl =
        TextEditingController(text: s.defaultStockBarLengthCm.toString());
    _kerfCtrl = TextEditingController(text: s.defaultSawKerfMm.toString());
    _minOneM2 = s.enforceMinimumOneSquareMeter;
  }

  Future<void> _saveGeneralPricing() async {
    final updated = PricingSettings(
      doubleSpacerPricePerMeter:
          double.tryParse(_spacerPriceCtrl.text.trim()) ?? 45.0,
      georgianBarPricePerMeter:
          double.tryParse(_georgianPriceCtrl.text.trim()) ?? 85.0,
      defaultStockBarLengthCm:
          double.tryParse(_barLenCtrl.text.trim()) ?? 600.0,
      defaultSawKerfMm: double.tryParse(_kerfCtrl.text.trim()) ?? 4.0,
      enforceMinimumOneSquareMeter: _minOneM2,
    );
    await widget.storage.updatePricingSettings(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('تم حفظ أسعار السبيسر والجورجيا وإعدادات القص بنجاح')),
    );
  }

  void _showGlassDialog({GlassTypeItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null
            ? existing.pricePerSquareMeter.toStringAsFixed(0)
            : '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة نوع زجاج جديد' : 'تعديل سعر الزجاج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم ونوع فردة الزجاج',
                hintText: 'مثال: زجاج عاكس بني 6 مم / سيكوريت 10 مم',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'سعر المتر المربع للفردة الواحدة (ج.م)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 450.0;
              await widget.storage.addOrUpdateGlassType(
                GlassTypeItem(
                  id: existing?.id ??
                      'glass_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  pricePerSquareMeter: price,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editSectorPriceDialog(SectorProfile sector) {
    final ctrl = TextEditingController(
        text: sector.pricePerSquareMeter.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تسعير متر قطاع: ${sector.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'سعر المتر المربع للقطاع (ج.م)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final p =
                  double.tryParse(ctrl.text.trim()) ?? sector.pricePerSquareMeter;
              await widget.storage.updateSectorPrice(sector.id, p);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('تحديث السعر'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectors = widget.storage.sectors;
    final glasses = widget.storage.glassTypes;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. قائمة تسعير القطاعات (سعر المتر لكل قطاع)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. قائمة تسعير القطاعات (سعر المتر المربع لكل قطاع):',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'اضغط على أي قطاع لتعديل سعر المتر الخاص به، وسيتم تطبيقه تلقائياً في عروض أسعار العملاء:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    const Divider(),
                    ...sectors.map((sec) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            sec.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          subtitle: Text('المجموعة: ${sec.companyGroup} | النظام: ${sec.systemType}'),
                          trailing: OutlinedButton.icon(
                            onPressed: () => _editSectorPriceDialog(sec),
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(
                              '${sec.pricePerSquareMeter.toStringAsFixed(0)} ج.م / م²',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B)),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. قائمة أنواع الزجاج وتسعير الفردة الواحدة
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '2. قائمة تسعير أنواع الزجاج (سعر المتر للفردة):',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showGlassDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة نوع زجاج'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'في حالة اختيار "زجاج دبل" للعميل، يجمع البرنامج تلقائياً (سعر الفردة الأولى + سعر الفردة الثانية + سعر السبيسر بالأسفل).',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                    const Divider(),
                    ...glasses.map((g) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            g.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${g.pricePerSquareMeter.toStringAsFixed(0)} ج.م / م²',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                  fontSize: 13,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18, color: Color(0xFF1D4ED8)),
                                onPressed: () => _showGlassDialog(existing: g),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () =>
                                    widget.storage.deleteGlassType(g.id),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. تسعير السبيسر (للزجاج الدبل) وتسعير الجورجيا وإعدادات العود
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. تسعير السبيسر (للزجاج الدبل) والجورجيا وإعدادات القص:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _spacerPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر متر السبيسر حول الزجاج الدبل (ج.م)',
                              helperText: 'يُضاف تلقائياً على ثمن فردتي الزجاج الدبل',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _georgianPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر متر الجورجيا (ج.م / متر طولي)',
                              helperText: 'يُضاف عند تفعيل الجورجيا في الشباك',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barLenCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'طول العود القياسي (سم)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _kerfCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سُمك صينية المنشار (مم)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'احتساب الشباك الأقل من 1 م² على أنه 1 متر مربع كحد أدنى؟',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      value: _minOneM2,
                      onChanged: (v) => setState(() => _minOneM2 = v),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saveGeneralPricing,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'حفظ إعدادات السبيسر والجورجيا والقص',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
