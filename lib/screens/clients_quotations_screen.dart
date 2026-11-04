import 'dart:io';
import 'package:flutter/material.dart';
import '../models/workshop_models.dart';
import '../services/pdf_generator_service.dart';
import '../services/workshop_storage.dart';
import '../widgets/window_2d_visualizer.dart';

class ClientsQuotationsScreen extends StatefulWidget {
  final WorkshopStorage storage;
  const ClientsQuotationsScreen({super.key, required this.storage});

  @override
  State<ClientsQuotationsScreen> createState() =>
      _ClientsQuotationsScreenState();
}

class _ClientsQuotationsScreenState extends State<ClientsQuotationsScreen> {
  String _searchQuery = '';

  void _openClientEditor({ClientRecord? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientQuotationEditorPage(
          storage: widget.storage,
          existingClient: existing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allClients = widget.storage.clients;
    final filtered = _searchQuery.trim().isEmpty
        ? allClients
        : allClients
            .where((c) =>
                c.clientName.contains(_searchQuery) ||
                c.clientPhone.contains(_searchQuery))
            .toList();

    final bool minOneM2 =
        widget.storage.pricingSettings.enforceMinimumOneSquareMeter;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'ابحث في سجل العملاء بالاسم أو الهاتف...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1D1D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onPressed: () => _openClientEditor(),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text(
                    'مقايسة عميل جديدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_shared_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'لا يوجد عملاء محفوظون في السجل حتى الآن',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ارفع مقاسات العميل مع شاشة المعاينة الهندسية التفاعلية\nواستخرج كشف عرض السعر بالرسم والمواصفات لكل شباك',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _openClientEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('بدء رفع مقاسات عميل جديد'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final client = filtered[idx];
                      double totalPrice = 0.0;
                      for (final item in client.items) {
                        final sec =
                            widget.storage.getSectorById(item.sectorId);
                        totalPrice += item.calculateTotalCost(sec,
                            minOneM2: minOneM2);
                      }
                      final netPrice = (totalPrice - client.discountAmount)
                          .clamp(0.0, double.infinity);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'العميل: ${client.clientName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFF7F1D1D)),
                                    ),
                                    child: Text(
                                      'الصافي: ${netPrice.toStringAsFixed(1)} ج.م',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7F1D1D),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'التاريخ: ${client.createdAt} • عدد الفتحات: ${client.items.length} فتحة ${client.clientPhone.isNotEmpty ? "• هاتف: ${client.clientPhone}" : ""}',
                                style: const TextStyle(
                                    fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                              const Divider(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D4ED8),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        _openClientEditor(existing: client),
                                    icon: const Icon(Icons.edit_note, size: 18),
                                    label: const Text('فتح وتعديل المقايسة'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      final bytes = await PdfGeneratorService
                                          .buildQuotationPdfBytes(
                                        client: client,
                                        storage: widget.storage,
                                      );
                                      await PdfGeneratorService.savePdfToDeviceStorage(
                                        bytes: bytes,
                                        fileName: 'عرض_سعر_شركة_الحافظ_${client.clientName}.pdf',
                                      );
                                      await PdfGeneratorService.previewPdfBytes(
                                          bytes,
                                          'عرض_سعر_شركة_الحافظ_${client.clientName}.pdf');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم حفظ عرض السعر في التحميلات Download')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.picture_as_pdf,
                                        size: 17, color: Color(0xFF7F1D1D)),
                                    label: const Text('PDF (1) عرض السعر بالرسم'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      final bytes = await PdfGeneratorService
                                          .buildOrderAndCuttingPdfBytes(
                                        client: client,
                                        storage: widget.storage,
                                      );
                                      await PdfGeneratorService.savePdfToDeviceStorage(
                                        bytes: bytes,
                                        fileName: 'كشف_طلبية_شركة_الحافظ_${client.clientName}.pdf',
                                      );
                                      await PdfGeneratorService.previewPdfBytes(
                                          bytes,
                                          'كشف_طلبية_شركة_الحافظ_${client.clientName}.pdf');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم حفظ كشف الطلبية في التحميلات Download')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.fact_check_outlined,
                                        size: 17, color: Color(0xFF15803D)),
                                    label: const Text('PDF (2) كشف الطلبية'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF15803D),
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () async {
                                      await PdfGeneratorService
                                          .generateAndShareBothPdfs(
                                        client: client,
                                        storage: widget.storage,
                                      );
                                    },
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('مشاركة وحفظ الـ 2 PDF'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () => widget.storage
                                        .deleteClientRecord(client.id),
                                  ),
                                ],
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
}

/// صفحة رفع المقاسات مع المعاينة الحية وإضافة الفتحات للأعلى في قائمة المقايسة
class ClientQuotationEditorPage extends StatefulWidget {
  final WorkshopStorage storage;
  final ClientRecord? existingClient;

  const ClientQuotationEditorPage({
    super.key,
    required this.storage,
    this.existingClient,
  });

  @override
  State<ClientQuotationEditorPage> createState() =>
      _ClientQuotationEditorPageState();
}

class _ClientQuotationEditorPageState extends State<ClientQuotationEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientAddressCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _depositCtrl = TextEditingController(text: '0');
  final _archCostCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  List<ClientWindowItem> _items = [];
  late String _recordId;
  late String _createdAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final ex = widget.existingClient;
    if (ex != null) {
      _recordId = ex.id;
      _createdAt = ex.createdAt;
      _clientNameCtrl.text = ex.clientName;
      _clientPhoneCtrl.text = ex.clientPhone;
      _clientAddressCtrl.text = ex.clientAddress;
      _discountCtrl.text = ex.discountAmount.toStringAsFixed(0);
      _depositCtrl.text = ex.depositAmount.toStringAsFixed(0);
      _archCostCtrl.text = ex.archCost.toStringAsFixed(0);
      _notesCtrl.text = ex.notes;
      _items = ex.items
          .map((e) => ClientWindowItem.fromJson(e.toJson()))
          .toList();
    } else {
      final now = DateTime.now();
      _recordId = 'client_${now.millisecondsSinceEpoch}';
      _createdAt =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  ClientRecord _buildCurrentRecord() {
    return ClientRecord(
      id: _recordId,
      clientName: _clientNameCtrl.text.trim().isEmpty
          ? 'عميل بدون اسم'
          : _clientNameCtrl.text.trim(),
      clientPhone: _clientPhoneCtrl.text.trim(),
      clientAddress: _clientAddressCtrl.text.trim(),
      createdAt: _createdAt,
      notes: _notesCtrl.text.trim(),
      discountAmount: double.tryParse(_discountCtrl.text.trim()) ?? 0.0,
      depositAmount: double.tryParse(_depositCtrl.text.trim()) ?? 0.0,
      archCost: double.tryParse(_archCostCtrl.text.trim()) ?? 0.0,
      items: _items,
    );
  }

  Future<void> _saveClientToHistory() async {
    if (_clientNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم العميل أولاً')),
      );
      return;
    }
    final record = _buildCurrentRecord();
    await widget.storage.saveClientRecord(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ مقايسة العميل "${record.clientName}" بنجاح')),
    );
  }

  /// نافذة إضافة الفتحة مع المعاينة الحية المباشرة وهي بتترسم فوق فوراً
  void _showAddOrEditWindowModal({ClientWindowItem? existing, int? editIdx}) {
    final sectors = widget.storage.sectors;
    final glasses = widget.storage.glassTypes;
    if (sectors.isEmpty) return;

    SectorProfile selectedSector = existing != null
        ? (widget.storage.getSectorById(existing.sectorId) ?? sectors.first)
        : sectors.first;

    final labelCtrl = TextEditingController(
        text: existing?.label ?? 'فتحة رقم ${_items.length + 1}');
    final widthCtrl = TextEditingController(
        text: existing != null ? existing.widthCm.toString() : '150');
    final heightCtrl = TextEditingController(
        text: existing != null ? existing.heightCm.toString() : '120');
    final qtyCtrl = TextEditingController(
        text: existing != null ? existing.quantity.toString() : '1');

    String unitType = existing?.unitType ?? 'شباك';
    String openType = existing?.openType ?? 'جرار';
    String barType = existing?.barType ?? 'بار عادي';
    String openDirection = existing?.openDirection ?? 'يمين للداخل';
    String sectorColor = existing?.sectorColor ?? 'بيج';

    int sashCount = existing?.sashCount ?? selectedSector.defaultSashCount;
    bool hasGlass = existing?.hasGlass ?? true;
    bool isDoubleGlass = existing?.isDoubleGlass ?? false;

    GlassTypeItem glass1 = glasses.isNotEmpty
        ? glasses.firstWhere((g) => g.id == existing?.glass1Id,
            orElse: () => glasses.first)
        : GlassTypeItem(id: 'g1', name: 'زجاج شفاف 6 مم', pricePerSquareMeter: 450);

    GlassTypeItem glass2 = glasses.length > 1
        ? glasses.firstWhere((g) => g.id == existing?.glass2Id,
            orElse: () => glasses[1])
        : glass1;

    bool hasGeorgian = existing?.hasGeorgianBars ?? false;
    final georgianMetersCtrl = TextEditingController(
        text: existing != null ? existing.georgianMetersPerWindow.toString() : '3.0');

    // إعدادات التكوين المعماري المتقدم (الثوابت والشفاط)
    bool hasTopFixed = existing?.hasTopFixed ?? false;
    final topFixedCtrl = TextEditingController(
        text: existing != null ? existing.topFixedHeightCm.toString() : '40.0');

    bool hasBottomFixed = existing?.hasBottomFixed ?? false;
    final bottomFixedCtrl = TextEditingController(
        text: existing != null ? existing.bottomFixedHeightCm.toString() : '40.0');

    bool hasRightFixed = existing?.hasRightFixed ?? false;
    final rightFixedCtrl = TextEditingController(
        text: existing != null ? existing.rightFixedWidthCm.toString() : '40.0');

    bool hasLeftFixed = existing?.hasLeftFixed ?? false;
    final leftFixedCtrl = TextEditingController(
        text: existing != null ? existing.leftFixedWidthCm.toString() : '40.0');

    bool hasExhaustFan = existing?.hasExhaustFan ?? false;
    String exhaustFanShape = existing?.exhaustFanShape ?? 'دائري';
    final exhaustFanDiameterCtrl = TextEditingController(
        text: existing != null ? existing.exhaustFanDiameterCm.toString() : '25.0');
    String exhaustFanPosition = existing?.exhaustFanPosition ?? 'في الثابت العلوي';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final double curW = double.tryParse(widthCtrl.text.trim()) ?? 150.0;
          final double curH = double.tryParse(heightCtrl.text.trim()) ?? 120.0;
          final double singleArea = (curW / 100.0) * (curH / 100.0);
          final int curQty = int.tryParse(qtyCtrl.text.trim()) ?? 1;

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // رأس المودال
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B110A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'إضافة فتحة جديدة مع المعاينة' : 'تعديل الفتحة',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. شاشة المعاينة الهندسية التفاعلية الفورية (تترسم مباشرة أثناء تغيير الأبعاد والخيارات)
                        Window2DVisualizer(
                          widthCm: curW,
                          heightCm: curH,
                          unitType: unitType,
                          openType: openType,
                          sashCount: sashCount,
                          barType: barType,
                          openDirection: openDirection,
                          sectorColor: sectorColor,
                          hasTopFixed: hasTopFixed,
                          topFixedHeightCm: double.tryParse(topFixedCtrl.text.trim()) ?? 40.0,
                          hasBottomFixed: hasBottomFixed,
                          bottomFixedHeightCm: double.tryParse(bottomFixedCtrl.text.trim()) ?? 40.0,
                          hasRightFixed: hasRightFixed,
                          rightFixedWidthCm: double.tryParse(rightFixedCtrl.text.trim()) ?? 40.0,
                          hasLeftFixed: hasLeftFixed,
                          leftFixedWidthCm: double.tryParse(leftFixedCtrl.text.trim()) ?? 40.0,
                          hasExhaustFan: hasExhaustFan,
                          exhaustFanShape: exhaustFanShape,
                          exhaustFanDiameterCm: double.tryParse(exhaustFanDiameterCtrl.text.trim()) ?? 25.0,
                          exhaustFanPosition: exhaustFanPosition,
                          hasGlass: hasGlass,
                          isDoubleGlass: isDoubleGlass,
                          hasGeorgian: hasGeorgian,
                          height: 220,
                        ),
                        const SizedBox(height: 12),

                        // أزرار التحكم السريع في اتجاهات الثوابت والشفاط
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إضافة ثوابت الفتحة المعمارية (انقر للإضافة الفورية):',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChip(
                                      selected: hasTopFixed,
                                      selectedColor: const Color(0xFFD97706),
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: hasTopFixed ? Colors.white : const Color(0xFF1B110A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      label: const Text('⬆️ ثابت فوق'),
                                      onSelected: (v) => setModalState(() => hasTopFixed = v),
                                    ),
                                    const SizedBox(width: 6),
                                    FilterChip(
                                      selected: hasBottomFixed,
                                      selectedColor: const Color(0xFFD97706),
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: hasBottomFixed ? Colors.white : const Color(0xFF1B110A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      label: const Text('⬇️ ثابت تحت'),
                                      onSelected: (v) => setModalState(() => hasBottomFixed = v),
                                    ),
                                    const SizedBox(width: 6),
                                    FilterChip(
                                      selected: hasRightFixed,
                                      selectedColor: const Color(0xFFD97706),
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: hasRightFixed ? Colors.white : const Color(0xFF1B110A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      label: const Text('➡️ ثابت يمين'),
                                      onSelected: (v) => setModalState(() => hasRightFixed = v),
                                    ),
                                    const SizedBox(width: 6),
                                    FilterChip(
                                      selected: hasLeftFixed,
                                      selectedColor: const Color(0xFFD97706),
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: hasLeftFixed ? Colors.white : const Color(0xFF1B110A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      label: const Text('⬅️ ثابت شمال'),
                                      onSelected: (v) => setModalState(() => hasLeftFixed = v),
                                    ),
                                    const SizedBox(width: 6),
                                    FilterChip(
                                      selected: hasExhaustFan,
                                      selectedColor: const Color(0xFFB91C1C),
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: hasExhaustFan ? Colors.white : const Color(0xFF1B110A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      label: const Text('🌀 فتحة شفاط'),
                                      onSelected: (v) => setModalState(() => hasExhaustFan = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // مؤشر المساحة والسعر الفوري للمتر
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD97706)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'مساحة الفتحة: ${singleArea.toStringAsFixed(2)} م² (الإجمالي: ${(singleArea * curQty).toStringAsFixed(2)} م²)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF92400E)),
                              ),
                              Text(
                                'سعر المتر: ${selectedSector.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. إدخال المقاسات والوصف
                        TextField(
                          controller: labelCtrl,
                          decoration: const InputDecoration(
                            labelText: 'وصف الفتحة / الغرفة (شباك صالة، باب بلكونة، مطبخ...)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widthCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setModalState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'العرض (سم)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: heightCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setModalState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'الارتفاع (سم)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setModalState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'العدد',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 3. خيارات المعاينة: نوع الفتحة وطريقة الفتح ونوع البار واتجاه الفتح
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: unitType,
                                decoration: const InputDecoration(labelText: 'نوع الفتحة', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'شباك', child: Text('🪟 شباك')),
                                  DropdownMenuItem(value: 'باب', child: Text('🚪 باب')),
                                  DropdownMenuItem(value: 'مطبخ', child: Text('🍳 مطبخ')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => unitType = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: openType,
                                decoration: const InputDecoration(labelText: 'طريقة الفتح', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'جرار', child: Text('جرار (منزلق)')),
                                  DropdownMenuItem(value: 'مفصلي', child: Text('مفصلي')),
                                  DropdownMenuItem(value: 'قلاب', child: Text('قلاب')),
                                  DropdownMenuItem(value: 'ثابت', child: Text('ثابت')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => openType = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: barType,
                                decoration: const InputDecoration(labelText: 'نوع البار', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'بار عادي', child: Text('بار عادي')),
                                  DropdownMenuItem(value: 'بار مقلوب', child: Text('بار مقلوب')),
                                  DropdownMenuItem(value: 'بدون بار', child: Text('بدون بار')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => barType = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: sectorColor,
                                decoration: const InputDecoration(labelText: 'لون القطاع', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'بيج', child: Text('بيج')),
                                  DropdownMenuItem(value: 'أبيض', child: Text('أبيض')),
                                  DropdownMenuItem(value: 'أسود', child: Text('أسود')),
                                  DropdownMenuItem(value: 'رمادي', child: Text('رمادي')),
                                  DropdownMenuItem(value: 'خشابي', child: Text('خشابي')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => sectorColor = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: openDirection,
                                decoration: const InputDecoration(labelText: 'اتجاه الفتح', border: OutlineInputBorder(), isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'يمين للداخل', child: Text('يمين للداخل')),
                                  DropdownMenuItem(value: 'شمال للداخل', child: Text('شمال للداخل')),
                                  DropdownMenuItem(value: 'يمين للخارج', child: Text('يمين للخارج')),
                                  DropdownMenuItem(value: 'شمال للخارج', child: Text('شمال للخارج')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => openDirection = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // عدد الضلف
                        DropdownButtonFormField<int>(
                          value: sashCount,
                          decoration: const InputDecoration(labelText: 'عدد الضلف', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 ضلفة')),
                            DropdownMenuItem(value: 2, child: Text('2 ضلفة')),
                            DropdownMenuItem(value: 3, child: Text('3 ضلفة')),
                            DropdownMenuItem(value: 4, child: Text('4 ضلفة')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModalState(() => sashCount = v);
                          },
                        ),
                        const SizedBox(height: 10),

                        // اختيار القطاع (الـ 25 قطاعاً بجميع الشركات)
                        DropdownButtonFormField<String>(
                          value: selectedSector.id,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'القطاع وخلوصات التخصيم', border: OutlineInputBorder(), isDense: true),
                          items: sectors.map((s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Row(
                              children: [
                                if (s.imagePath != null && s.imagePath!.isNotEmpty && File(s.imagePath!).existsSync())
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Image.file(File(s.imagePath!), width: 20, height: 20, fit: BoxFit.cover),
                                  ),
                                Expanded(
                                  child: Text(
                                    '[${s.companyGroup}] ${s.name} (${s.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final found = widget.storage.getSectorById(val);
                              if (found != null) {
                                setModalState(() => selectedSector = found);
                              }
                            }
                          },
                        ),
                        const Divider(height: 22),

                        // إعدادات الزجاج
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('إضافة زجاج', style: TextStyle(fontWeight: FontWeight.bold)),
                          value: hasGlass,
                          onChanged: (v) => setModalState(() => hasGlass = v),
                        ),
                        if (hasGlass) ...[
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(value: false, label: Text('سنجل (فردة)')),
                              ButtonSegment<bool>(value: true, label: Text('دبل (فردتين + سبيسر)')),
                            ],
                            selected: {isDoubleGlass},
                            onSelectionChanged: (s) => setModalState(() => isDoubleGlass = s.first),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: glass1.id,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: isDoubleGlass ? 'فردة الزجاج الأولى' : 'نوع الزجاج',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: glasses.map((g) => DropdownMenuItem(
                              value: g.id,
                              child: Text('${g.name} (${g.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)', style: const TextStyle(fontSize: 12)),
                            )).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setModalState(() => glass1 = glasses.firstWhere((e) => e.id == v));
                              }
                            },
                          ),
                          if (isDoubleGlass) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: glass2.id,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'فردة الزجاج الثانية (دبل)', border: OutlineInputBorder(), isDense: true),
                              items: glasses.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text('${g.name} (${g.pricePerSquareMeter.toStringAsFixed(0)} ج.م/م²)', style: const TextStyle(fontSize: 12)),
                              )).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setModalState(() => glass2 = glasses.firstWhere((e) => e.id == v));
                                }
                              },
                            ),
                          ],
                        ],
                        const Divider(height: 20),

                        // جورجيا
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('أعواد جورجيا (${widget.storage.pricingSettings.georgianBarPricePerMeter.toStringAsFixed(0)} ج.م/متر)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          value: hasGeorgian,
                          onChanged: (v) => setModalState(() => hasGeorgian = v),
                        ),
                        if (hasGeorgian)
                          TextField(
                            controller: georgianMetersCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setModalState(() {}),
                            decoration: const InputDecoration(labelText: 'أمتار الجورجيا بالفتحة', border: OutlineInputBorder(), isDense: true),
                          ),
                      ],
                    ),
                  ),
                ),

                        const Divider(height: 22),
                        const Text(
                          'التكوين المعماري المتقدم (الثوابت والشفاط):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B110A)),
                        ),
                        const SizedBox(height: 8),

                        // ثابت علوي
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ثابت علوي (جلسة علوية)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: const Text('تقسيم الفتحة بجزء ثابت في الأعلى ومتحرك بالأسفل', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          value: hasTopFixed,
                          onChanged: (v) => setModalState(() => hasTopFixed = v),
                        ),
                        if (hasTopFixed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              controller: topFixedCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setModalState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'ارتفاع الثابت العلوي (سم)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),

                        // ثابت سفلي
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('ثابت سفلي (جلسة سفلية)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          value: hasBottomFixed,
                          onChanged: (v) => setModalState(() => hasBottomFixed = v),
                        ),
                        if (hasBottomFixed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              controller: bottomFixedCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setModalState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'ارتفاع الثابت السفلي (سم)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),

                        // ثوابت جانبية (يمين / شمال)
                        Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('ثابت يمين', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                value: hasRightFixed,
                                onChanged: (v) => setModalState(() => hasRightFixed = v),
                              ),
                            ),
                            Expanded(
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('ثابت شمال', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                value: hasLeftFixed,
                                onChanged: (v) => setModalState(() => hasLeftFixed = v),
                              ),
                            ),
                          ],
                        ),
                        if (hasRightFixed || hasLeftFixed) ...[
                          Row(
                            children: [
                              if (hasRightFixed)
                                Expanded(
                                  child: TextField(
                                    controller: rightFixedCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setModalState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'عرض ثابت يمين (سم)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              if (hasRightFixed && hasLeftFixed) const SizedBox(width: 8),
                              if (hasLeftFixed)
                                Expanded(
                                  child: TextField(
                                    controller: leftFixedCtrl,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setModalState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'عرض ثابت شمال (سم)',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        // فتحة الشفاط (Exhaust Fan)
                        const Divider(height: 18),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('إضافة فتحة شفاط (للمطابخ والحمامات)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB91C1C))),
                          subtitle: const Text('تفريغ فتحة دائرية أو مربعة لتركيب الشفاط', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          value: hasExhaustFan,
                          onChanged: (v) => setModalState(() => hasExhaustFan = v),
                        ),
                        if (hasExhaustFan) ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: exhaustFanShape,
                                  decoration: const InputDecoration(labelText: 'شكل الشفاط', border: OutlineInputBorder(), isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 'دائري', child: Text('دائري ⭕')),
                                    DropdownMenuItem(value: 'مربع', child: Text('مربع ⏹️')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setModalState(() => exhaustFanShape = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: exhaustFanDiameterCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setModalState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'القطر / الضلع (سم)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: exhaustFanPosition,
                            decoration: const InputDecoration(labelText: 'موضع فتحة الشفاط', border: OutlineInputBorder(), isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'في الثابت العلوي', child: Text('في الثابت العلوي')),
                              DropdownMenuItem(value: 'في الدرفة يمين', child: Text('في الدرفة يمين')),
                              DropdownMenuItem(value: 'في الدرفة شمال', child: Text('في الدرفة شمال')),
                            ],
                            onChanged: (v) {
                              if (v != null) setModalState(() => exhaustFanPosition = v);
                            },
                          ),
                        ],
                        const SizedBox(height: 14),

                // زر تأكيد الإضافة لتنزل الفتحة فوراً في القائمة العلوية
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final w = double.tryParse(widthCtrl.text.trim()) ?? 120.0;
                        final h = double.tryParse(heightCtrl.text.trim()) ?? 120.0;
                        final q = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                        final geoM = double.tryParse(georgianMetersCtrl.text.trim()) ?? 0.0;

                        final tfH = double.tryParse(topFixedCtrl.text.trim()) ?? 40.0;
                        final bfH = double.tryParse(bottomFixedCtrl.text.trim()) ?? 40.0;
                        final rfW = double.tryParse(rightFixedCtrl.text.trim()) ?? 40.0;
                        final lfW = double.tryParse(leftFixedCtrl.text.trim()) ?? 40.0;
                        final fanD = double.tryParse(exhaustFanDiameterCtrl.text.trim()) ?? 25.0;

                        final newItem = ClientWindowItem(
                          id: existing?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                          label: labelCtrl.text.trim().isEmpty ? '$unitType $openType' : labelCtrl.text.trim(),
                          unitType: unitType,
                          openType: openType,
                          barType: barType,
                          openDirection: openDirection,
                          hasTopFixed: hasTopFixed,
                          topFixedHeightCm: tfH,
                          hasBottomFixed: hasBottomFixed,
                          bottomFixedHeightCm: bfH,
                          hasRightFixed: hasRightFixed,
                          rightFixedWidthCm: rfW,
                          hasLeftFixed: hasLeftFixed,
                          leftFixedWidthCm: lfW,
                          hasExhaustFan: hasExhaustFan,
                          exhaustFanShape: exhaustFanShape,
                          exhaustFanDiameterCm: fanD,
                          exhaustFanPosition: exhaustFanPosition,
                          sectorId: selectedSector.id,
                          sectorName: selectedSector.name,
                          sectorPricePerM2: selectedSector.pricePerSquareMeter,
                          widthCm: w,
                          heightCm: h,
                          quantity: q > 0 ? q : 1,
                          sashCount: sashCount,
                          hasGlass: hasGlass,
                          isDoubleGlass: isDoubleGlass,
                          glass1Id: glass1.id,
                          glass1Name: glass1.name,
                          glass1PricePerM2: glass1.pricePerSquareMeter,
                          glass2Id: glass2.id,
                          glass2Name: glass2.name,
                          glass2PricePerM2: glass2.pricePerSquareMeter,
                          spacerPricePerMeter: widget.storage.pricingSettings.doubleSpacerPricePerMeter,
                          hasGeorgianBars: hasGeorgian,
                          georgianMetersPerWindow: hasGeorgian ? geoM : 0.0,
                          georgianPricePerMeter: widget.storage.pricingSettings.georgianBarPricePerMeter,
                        );

                        setState(() {
                          if (editIdx != null) {
                            _items[editIdx] = newItem;
                          } else {
                            // إضافة الفتحة في أعلى القائمة لتظهر فوق فوراً
                            _items.insert(0, newItem);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text(
                        'إضافة الفتحة إلى قائمة المقايسة فوق',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool minOneM2 = widget.storage.pricingSettings.enforceMinimumOneSquareMeter;

    double totalSectorsCost = 0.0;
    double totalGlassCost = 0.0;
    double totalGeoCost = 0.0;
    double totalAreaAll = 0.0;

    for (final item in _items) {
      final sec = widget.storage.getSectorById(item.sectorId);
      final area = item.totalAreaM2(minOneM2: minOneM2);
      totalAreaAll += area;
      totalSectorsCost += item.calculateSectorCost(minOneM2: minOneM2);
      totalGlassCost += item.calculateGlassAndSpacerCost(sec, minOneM2: minOneM2);
      totalGeoCost += item.calculateGeorgianCost();
    }
    final double discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    final double grandNet = (totalSectorsCost + totalGlassCost + totalGeoCost - discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مقايسة عميل — شركة الحافظ'),
        backgroundColor: const Color(0xFF1B110A),
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveClientToHistory,
            icon: const Icon(Icons.save, color: Color(0xFFF59E0B)),
            label: const Text('حفظ بالسجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFF59E0B),
          tabs: const [
            Tab(icon: Icon(Icons.request_quote), text: '1. كشف عرض السعر بالرسم'),
            Tab(icon: Icon(Icons.carpenter), text: '2. كشف الطلبية والتخصيم'),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط بيانات العميل وزر إضافة فتحة
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFF8FAFC),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _clientNameCtrl,
                        decoration: const InputDecoration(labelText: 'اسم العميل', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _clientPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'رقم الهاتف', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'الخصم (ج.م)', isDense: true, filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () => _showAddOrEditWindowModal(),
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text(
                      '+ إضافة فتحة جديدة (تترسم بالمعاينة الهندسية وتتضاف فوق)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuotationTabWithDrawings(minOneM2, totalAreaAll, totalSectorsCost, totalGlassCost, totalGeoCost, grandNet),
                _buildOrderAndCuttingTab(),
              ],
            ),
          ),

          // شريط أزرار تصدير الـ 2 PDF في الأسفل مع التوتال النهائي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF1B110A),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      onPressed: () async {
                        await _saveClientToHistory();
                        final rec = _buildCurrentRecord();
                        final bytes = await PdfGeneratorService.buildQuotationPdfBytes(client: rec, storage: widget.storage);
                        final p = await PdfGeneratorService.savePdfToDeviceStorage(bytes: bytes, fileName: 'عرض_سعر_شركة_الحافظ_${rec.clientName}.pdf');
                        await PdfGeneratorService.previewPdfBytes(bytes, 'عرض_سعر_شركة_الحافظ_${rec.clientName}.pdf');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ عرض السعر في التحميلات: $p')));
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF عرض السعر', style: TextStyle(fontSize: 11.5)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      onPressed: () async {
                        await _saveClientToHistory();
                        final rec = _buildCurrentRecord();
                        final bytes = await PdfGeneratorService.buildOrderAndCuttingPdfBytes(client: rec, storage: widget.storage);
                        final p = await PdfGeneratorService.savePdfToDeviceStorage(bytes: bytes, fileName: 'كشف_طلبية_شركة_الحافظ_${rec.clientName}.pdf');
                        await PdfGeneratorService.previewPdfBytes(bytes, 'كشف_طلبية_شركة_الحافظ_${rec.clientName}.pdf');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ كشف الطلبية في التحميلات: $p')));
                        }
                      },
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: const Text('PDF كشف الطلبية', style: TextStyle(fontSize: 11.5)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white),
                      onPressed: () async {
                        await _saveClientToHistory();
                        final rec = _buildCurrentRecord();
                        await PdfGeneratorService.generateAndShareBothPdfs(client: rec, storage: widget.storage);
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('مشاركة الـ 2 PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// كشف عرض السعر بالرسم الهندسي الكروكي لكل شباك وسعره ومقاسه والمساحة والتوتال النهائي
  Widget _buildQuotationTabWithDrawings(
    bool minOneM2,
    double totalAreaAll,
    double totalSectorsCost,
    double totalGlassCost,
    double totalGeoCost,
    double grandNet,
  ) {
    if (_items.isEmpty) {
      return const Center(child: Text('أضف فتحات من الزر بالأعلى لتظهر مرسومة بالمعاينة مع أسعارها هنا'));
    }
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        ...List.generate(_items.length, (idx) {
          final item = _items[idx];
          final sec = widget.storage.getSectorById(item.sectorId);
          final singleArea = item.singleWindowAreaM2(minOneM2: minOneM2);
          final area = item.totalAreaM2(minOneM2: minOneM2);
          final secCost = item.calculateSectorCost(minOneM2: minOneM2);
          final glCost = item.calculateGlassAndSpacerCost(sec, minOneM2: minOneM2);
          final geoCost = item.calculateGeorgianCost();
          final total = secCost + glCost + geoCost;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // رسم الشباك 2D المصغر
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 82,
                      height: 72,
                      child: Window2DVisualizer(
                        widthCm: item.widthCm,
                        heightCm: item.heightCm,
                        unitType: item.unitType,
                        openType: item.openType,
                        sashCount: item.sashCount,
                        barType: item.barType,
                        openDirection: item.openDirection,
                        hasTopFixed: item.hasTopFixed,
                        topFixedHeightCm: item.topFixedHeightCm,
                        hasBottomFixed: item.hasBottomFixed,
                        bottomFixedHeightCm: item.bottomFixedHeightCm,
                        hasRightFixed: item.hasRightFixed,
                        rightFixedWidthCm: item.rightFixedWidthCm,
                        hasLeftFixed: item.hasLeftFixed,
                        leftFixedWidthCm: item.leftFixedWidthCm,
                        hasExhaustFan: item.hasExhaustFan,
                        exhaustFanShape: item.exhaustFanShape,
                        exhaustFanDiameterCm: item.exhaustFanDiameterCm,
                        exhaustFanPosition: item.exhaustFanPosition,
                        hasGlass: item.hasGlass,
                        isDoubleGlass: item.isDoubleGlass,
                        hasGeorgian: item.hasGeorgianBars,
                        height: 72,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // تفاصيل البند
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${idx + 1}. [${item.unitType} ${item.openType}] ${item.label}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        Text(
                          'المقاس: ${item.widthCm}×${item.heightCm} سم • العدد: ${item.quantity} • مساحة: ${singleArea.toStringAsFixed(2)} م² (إجمالي: ${area.toStringAsFixed(2)} م²)',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                        ),
                        Text(
                          'القطاع: ${item.sectorName} (${item.sectorPricePerM2.toStringAsFixed(0)} ج.م/م²) • البار: ${item.barType}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        ),
                        Text(
                          'الزجاج: ${item.glassSummaryText} ${item.hasGeorgianBars ? " + جورجيا" : ""}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // السعر الإجمالي للبند
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF7F1D1D)),
                        ),
                        child: Text(
                          '${total.toStringAsFixed(1)} ج.م',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D), fontSize: 13),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF1D4ED8), size: 18),
                            onPressed: () => _showAddOrEditWindowModal(existing: item, editIdx: idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () => setState(() => _items.removeAt(idx)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        // كشف التوتال المالي النهائي في الأسفل
        Card(
          color: const Color(0xFFFEF3C7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFD97706), width: 1.2)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي عدد الفتحات:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_items.length} فتحة (بإجمالي مساحة: ${totalAreaAll.toStringAsFixed(2)} م²)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي تكلفة القطاعات:'),
                    Text('${totalSectorsCost.toStringAsFixed(1)} ج.م'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي تكلفة الزجاج والسبيسر:'),
                    Text('${totalGlassCost.toStringAsFixed(1)} ج.م'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي تكلفة الجورجيا:'),
                    Text('${totalGeoCost.toStringAsFixed(1)} ج.م'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الصافي الإجمالي لعرض السعر (Total):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF7F1D1D)),
                    ),
                    Text(
                      '${grandNet.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderAndCuttingTab() {
    if (_items.isEmpty) {
      return const Center(child: Text('أضف فتحات لعرض كشف الطلبية والتخصيم هنا'));
    }
    return ListView(
      padding: const EdgeInsets.all(10),
      children: _items.map((item) {
        final sec = widget.storage.getSectorById(item.sectorId);
        final double gw = sec != null ? sec.calculateGlassWidthCm(item.widthCm, item.sashCount) : (item.widthCm / item.sashCount) - 10.0;
        final double gh = sec != null ? sec.calculateGlassHeightCm(item.heightCm, item.sashCount) : item.heightCm - 18.0;
        final int panesCount = item.sashCount * item.quantity;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.label} [${item.unitType} ${item.openType}] (${item.widthCm}×${item.heightCm} سم — العدد: ${item.quantity}) — ${item.sectorName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF15803D)),
                ),
                const Divider(),
                if (sec != null)
                  ...sec.parts.map((p) {
                    final len = p.calculatePieceLength(item.widthCm, item.heightCm, item.sashCount);
                    final cnt = p.calculateTotalCount(item.quantity, item.sashCount);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('• ${p.name}:'),
                          Text('طول القص: ${len.toStringAsFixed(1)} سم  |  العدد: $cnt قطعة', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                if (item.hasGlass) ...[
                  const Divider(),
                  Text(
                    item.isDoubleGlass
                        ? '• زجاج دبل صافي: ${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم — العدد: $panesCount فردة (${item.glass1Name}) + $panesCount فردة (${item.glass2Name}) + سبيسر: ${item.totalSpacerMeters(sec).toStringAsFixed(2)} م'
                        : '• زجاج سنجل صافي: ${gw.toStringAsFixed(1)} × ${gh.toStringAsFixed(1)} سم — العدد: $panesCount فردة (${item.glass1Name})',
                    style: const TextStyle(color: Color(0xFF7F1D1D), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
                if (item.hasGeorgianBars)
                  Text(
                    '• جورجيا: ${(item.georgianMetersPerWindow * item.quantity).toStringAsFixed(2)} متر طولي',
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
