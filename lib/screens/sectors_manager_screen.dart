import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/workshop_models.dart';
import '../services/workshop_storage.dart';

class SectorsManagerScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const SectorsManagerScreen({super.key, required this.storage});

  @override
  State<SectorsManagerScreen> createState() => _SectorsManagerScreenState();
}

class _SectorsManagerScreenState extends State<SectorsManagerScreen> {
  String _selectedGroupFilter = 'الكل';

  void _openSectorEditor({SectorProfile? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SectorEditorPage(
          storage: widget.storage,
          existingSector: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSectors = widget.storage.sectors;
    final groups = ['الكل', ...allSectors.map((e) => e.companyGroup).toSet()];

    final filtered = _selectedGroupFilter == 'الكل'
        ? allSectors
        : allSectors.where((s) => s.companyGroup == _selectedGroupFilter).toList();

    return Scaffold(
      body: Column(
        children: [
          // شريط معلومات وإضافة قطاع مخصص
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1B110A),
              border: Border(bottom: BorderSide(color: Color(0xFFD97706), width: 1.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.design_services, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'أضف أي قطاع جديد بالاسم والصورة وأضف أي مسمى تريده (سكينة، مكمل، تقابل، باكتة، محبس، إلخ) مع تحديد العدد والمعادلة.',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _openSectorEditor(),
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('إضافة قطاع جديد', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // شريط فلترة الشركات والقطاعات (الـ 25 قطاعاً الأصليين + المضافين)
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: groups.length,
              itemBuilder: (ctx, idx) {
                final grp = groups[idx];
                final isSel = grp == _selectedGroupFilter;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: FilterChip(
                    label: Text(grp),
                    selected: isSel,
                    selectedColor: const Color(0xFFD97706),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.black87,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedGroupFilter = grp),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final sec = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sec.isCustom ? const Color(0xFFD97706) : Colors.grey.shade300,
                      width: sec.isCustom ? 1.6 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: _buildSectorAvatar(sec),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sec.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: sec.isCustom ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: sec.isCustom ? const Color(0xFFD97706) : Colors.grey.shade400),
                          ),
                          child: Text(
                            sec.companyGroup,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: sec.isCustom ? const Color(0xFFB45309) : const Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'النوع: ${sec.systemType} (${sec.defaultSashCount} ضلفة) • سعر المتر: ${sec.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: sec.parts
                                .map((p) => Chip(
                                      visualDensity: VisualDensity.compact,
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                      backgroundColor: const Color(0xFFF8FAFC),
                                      label: Text(
                                        '${p.name} (عدد: ${p.quantityPerWindow}${p.multiplyBySashes ? "×ضلف" : ""})',
                                        style: const TextStyle(fontSize: 10.5),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'تعديل ومعاينة القطاع والأجزاء',
                          icon: const Icon(Icons.edit, color: Color(0xFF1D4ED8)),
                          onPressed: () => _openSectorEditor(existing: sec),
                        ),
                        if (sec.isCustom)
                          IconButton(
                            tooltip: 'حذف القطاع',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: Text('هل تريد حذف القطاع المخصص "${sec.name}"؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('إلغاء'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await widget.storage.deleteSector(sec.id);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorAvatar(SectorProfile sec) {
    if (sec.imagePath != null &&
        sec.imagePath!.isNotEmpty &&
        File(sec.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(sec.imagePath!),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD97706)),
      ),
      child: const Icon(Icons.window, color: Color(0xFFB45309), size: 28),
    );
  }
}

/// صفحة إضافة / تعديل القطاع وإضافة أي أجزاء حرة (سكينة، مكمل، تقابل، وغيرها)
class SectorEditorPage extends StatefulWidget {
  final WorkshopStorage storage;
  final SectorProfile? existingSector;

  const SectorEditorPage({
    super.key,
    required this.storage,
    this.existingSector,
  });

  @override
  State<SectorEditorPage> createState() => _SectorEditorPageState();
}

class _SectorEditorPageState extends State<SectorEditorPage> {
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _glassWDeductCtrl = TextEditingController();
  final _glassHDeductCtrl = TextEditingController();

  final _previewWCtrl = TextEditingController(text: '150');
  final _previewHCtrl = TextEditingController(text: '120');
  int _previewSashes = 2;

  String _systemType = 'شباك جرار';
  int _defaultSashCount = 2;
  String? _imagePath;
  List<SectorPart> _parts = [];

  @override
  void initState() {
    super.initState();
    final ex = widget.existingSector;
    if (ex != null) {
      _nameCtrl.text = ex.name;
      _companyCtrl.text = ex.companyGroup;
      _priceCtrl.text = ex.pricePerSquareMeter.toStringAsFixed(0);
      _glassWDeductCtrl.text = ex.glassWidthDeductCm.toString();
      _glassHDeductCtrl.text = ex.glassHeightDeductCm.toString();
      _systemType = ex.systemType;
      _defaultSashCount = ex.defaultSashCount;
      _previewSashes = ex.defaultSashCount;
      _imagePath = ex.imagePath;
      _parts = ex.parts
          .map((p) => SectorPart(
                id: p.id,
                name: p.name,
                role: p.role,
                dimensionBasis: p.dimensionBasis,
                offsetCm: p.offsetCm,
                quantityPerWindow: p.quantityPerWindow,
                multiplyBySashes: p.multiplyBySashes,
              ))
          .toList();
    } else {
      _companyCtrl.text = 'قطاع مخصص';
      _priceCtrl.text = '2400';
      _glassWDeductCtrl.text = '11.4';
      _glassHDeductCtrl.text = '11.4';
      _parts = [
        SectorPart(id: 'p1', name: 'حلق علوي وسفلي (عرض)', role: 'حلق', dimensionBasis: 'width', offsetCm: 0.0, quantityPerWindow: 2),
        SectorPart(id: 'p2', name: 'حلق جنبين (ارتفاع)', role: 'حلق', dimensionBasis: 'height', offsetCm: 0.0, quantityPerWindow: 2),
        SectorPart(id: 'p3', name: 'رأس وكعب ضلفة (عرض)', role: 'ضلفة', dimensionBasis: 'width_per_sash', offsetCm: 1.5, quantityPerWindow: 2, multiplyBySashes: true),
        SectorPart(id: 'p4', name: 'قائم ضلفة (ارتفاع)', role: 'ضلفة', dimensionBasis: 'height', offsetCm: -8.2, quantityPerWindow: 2, multiplyBySashes: true),
        SectorPart(id: 'p5', name: 'سكينة تداخل', role: 'سكينة', dimensionBasis: 'height', offsetCm: -8.2, quantityPerWindow: 2),
        SectorPart(id: 'p6', name: 'مكمل / تقابل بار', role: 'مكمل', dimensionBasis: 'height', offsetCm: 0.0, quantityPerWindow: 1),
      ];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الصورة: $e')),
      );
    }
  }

  /// نافذة إضافة أي جزء بالمسمى الحر (سكينة، مكمل، تقابل، حلق، ضلفة، باكتة، محبس، إلخ)
  void _showPartDialog({SectorPart? existingPart, int? editIndex}) {
    final nameCtrl = TextEditingController(text: existingPart?.name ?? '');
    final offsetCtrl = TextEditingController(
        text: existingPart != null ? existingPart.offsetCm.toString() : '0.0');
    final qtyCtrl = TextEditingController(
        text: existingPart != null ? existingPart.quantityPerWindow.toString() : '2');
    String role = existingPart?.role ?? 'سكينة';
    String basis = existingPart?.dimensionBasis ?? 'height';
    bool multSashes = existingPart?.multiplyBySashes ?? false;

    // اقتراحات مسميات سريعة يضغط عليها المستخدم أو يكتب مسمى من عنده
    final quickNames = ['سكينة', 'مكمل', 'تقابل', 'حلق', 'ضلفة', 'باكتة', 'محبس', 'بار زاوية', 'منخل سلك'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existingPart == null ? 'إضافة جزء جديد للقطاع' : 'تعديل بيانات الجزء'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الجزء (اكتب أي مسمى: سكينة، مكمل، تقابل...)',
                    hintText: 'مثال: سكينة تداخل / بار تقابل ضلفتين / مكمل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: quickNames.map((qn) => ActionChip(
                    label: Text(qn, style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      setDialogState(() {
                        nameCtrl.text = qn;
                        role = qn;
                        if (qn == 'حلق' || qn == 'ضلفة') {
                          basis = 'width';
                        } else {
                          basis = 'height';
                        }
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: basis,
                  decoration: const InputDecoration(
                    labelText: 'معادلة حساب مقاس الجزء بناءً على:',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'height', child: Text('الارتفاع الكلي للشباك/الباب (H)')),
                    DropdownMenuItem(value: 'width', child: Text('العرض الكلي للشباك/الباب (W)')),
                    DropdownMenuItem(value: 'width_per_sash', child: Text('العرض مقسوماً على عدد الضلف (W ÷ الضلف)')),
                    DropdownMenuItem(value: 'height_per_sash', child: Text('الارتفاع مقسوماً على عدد الضلف (H ÷ الضلف)')),
                    DropdownMenuItem(value: 'fixed', child: Text('مقاس ثابت بالسنتيمتر')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => basis = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: offsetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'قيمة التخصيم بالـ سم (مثال: -8.2 أو +1.5 أو 0)',
                    helperText: 'ضع سالب (-) للخصم من المقاس، أو موجب (+) للزيادة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'العدد (كم قطعة تتضاف للشباك/الباب؟)',
                    helperText: 'مثال: 2 قطعة للسكينة أو 1 قطعة للمكمل/التقابل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ضرب هذا العدد في عدد الضلف؟', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('فعّل هذا الخيار إذا كان العدد المذكور يخص الضلفة الواحدة', style: TextStyle(fontSize: 11)),
                  value: multSashes,
                  onChanged: (v) => setDialogState(() => multSashes = v),
                ),
              ],
            ),
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
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final offset = double.tryParse(offsetCtrl.text.trim()) ?? 0.0;
                final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

                final newPart = SectorPart(
                  id: existingPart?.id ?? 'part_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  role: role,
                  dimensionBasis: basis,
                  offsetCm: offset,
                  quantityPerWindow: qty > 0 ? qty : 1,
                  multiplyBySashes: multSashes,
                );

                setState(() {
                  if (editIndex != null) {
                    _parts[editIndex] = newPart;
                  } else {
                    _parts.add(newPart);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('حفظ الجزء'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSector() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم القطاع أولاً')),
      );
      return;
    }
    if (_parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة جزء واحد على الأقل للقطاع')),
      );
      return;
    }

    final sector = SectorProfile(
      id: widget.existingSector?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      companyGroup: _companyCtrl.text.trim().isEmpty ? 'مخصص' : _companyCtrl.text.trim(),
      systemType: _systemType,
      defaultSashCount: _defaultSashCount,
      imagePath: _imagePath,
      pricePerSquareMeter: double.tryParse(_priceCtrl.text.trim()) ?? 2200.0,
      glassWidthDeductCm: double.tryParse(_glassWDeductCtrl.text.trim()) ?? 11.4,
      glassHeightDeductCm: double.tryParse(_glassHDeductCtrl.text.trim()) ?? 11.4,
      isCustom: true,
      parts: _parts,
    );

    await widget.storage.addOrUpdateSector(sector);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ القطاع "${sector.name}" في قائمة القطاعات')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double pW = double.tryParse(_previewWCtrl.text) ?? 150.0;
    final double pH = double.tryParse(_previewHCtrl.text) ?? 120.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSector == null ? 'إضافة قطاع جديد بالصورة والأجزاء' : 'تعديل ومعاينة القطاع'),
        backgroundColor: const Color(0xFF1B110A),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveSector,
            icon: const Icon(Icons.check_circle, color: Color(0xFFF59E0B)),
            label: const Text('حفظ القطاع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. بيانات القطاع والصورة
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. بيانات القطاع وصورة المعاينة:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF991B1B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                            ),
                            child: (_imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync())
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: Color(0xFFB45309), size: 26),
                                      SizedBox(height: 4),
                                      Text('صورة القطاع', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameCtrl,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'اسم القطاع الجديد',
                                  hintText: 'مثال: قطاع جامبو خاص / قطاع الحافظ',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library, size: 16),
                                    label: const Text('استوديو', style: TextStyle(fontSize: 12)),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 16),
                                    label: const Text('كاميرا', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _systemType,
                            decoration: const InputDecoration(
                              labelText: 'نوع وفتح الفتحة (باب / شباك)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'شباك جرار', child: Text('شباك جرار')),
                              DropdownMenuItem(value: 'باب جرار', child: Text('باب جرار')),
                              DropdownMenuItem(value: 'شباك مفصلي', child: Text('شباك مفصلي')),
                              DropdownMenuItem(value: 'باب مفصلي', child: Text('باب مفصلي')),
                              DropdownMenuItem(value: 'قلاب / حمام', child: Text('قلاب')),
                              DropdownMenuItem(value: 'مطبخ', child: Text('قطاع مطابخ')),
                              DropdownMenuItem(value: 'مخصص', child: Text('نظام مخصص')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _systemType = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _companyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'اسم الشركة / المجموعة',
                              hintText: 'مثال: الشارقة، السعد، الحافظ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر المتر المربع (ج.م)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _glassWDeductCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'خصم عرض الزجاج (سم)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _glassHDeductCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'خصم ارتفاع الزجاج (سم)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. أجزاء القطاع المخصصة
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '2. أجزاء القطاع (سكينة، مكمل، تقابل، حلق، ضلفة، إلخ) والعدد:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF15803D)),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _showPartDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('إضافة جزء جديد'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_parts.length, (idx) {
                      final part = _parts[idx];
                      final sign = part.offsetCm >= 0 ? '+' : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                part.name,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${part.basisArabicLabel} ($sign${part.offsetCm} سم) | العدد: ${part.quantityPerWindow} قطعة ${part.multiplyBySashes ? "(×عدد الضلف)" : "(للشباك)"}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: Color(0xFF1D4ED8)),
                              onPressed: () => _showPartDialog(existingPart: part, editIndex: idx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => setState(() => _parts.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. شاشة المعاينة الفورية
            Card(
              color: const Color(0xFFFEF3C7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_imagePath != null && _imagePath!.isNotEmpty && File(_imagePath!).existsSync())
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(File(_imagePath!), width: 40, height: 40, fit: BoxFit.cover),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '3. شاشة المعاينة الفورية للقطاع: ${_nameCtrl.text.isEmpty ? "(اسم القطاع)" : _nameCtrl.text}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _previewWCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(labelText: 'عرض تجريبي (سم)', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _previewHCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(labelText: 'ارتفاع تجريبي (سم)', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _previewSashes,
                            decoration: const InputDecoration(labelText: 'عدد الضلف', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1 ضلفة')),
                              DropdownMenuItem(value: 2, child: Text('2 ضلفة')),
                              DropdownMenuItem(value: 3, child: Text('3 ضلفة')),
                              DropdownMenuItem(value: 4, child: Text('4 ضلفة')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _previewSashes = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('نتيجة مقاسات القص وعدد القطع في المعاينة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const Divider(height: 10),
                          ..._parts.map((p) {
                            final len = p.calculatePieceLength(pW, pH, _previewSashes);
                            final cnt = p.calculateTotalCount(1, _previewSashes);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('• ${p.name}:'),
                                  Text('المقاس: ${len.toStringAsFixed(1)} سم  |  العدد: $cnt قطعة', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                ),
                onPressed: _saveSector,
                icon: const Icon(Icons.save),
                label: const Text('حفظ القطاع في قائمة القطاعات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
