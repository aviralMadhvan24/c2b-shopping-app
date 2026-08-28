import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/store_section.dart';
import '../providers/admin_providers.dart';
import '../services/storage_service.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

/// Add or edit a product. Passing null for [product] opens it as "new".
class ProductEditorScreen extends ConsumerStatefulWidget {
  const ProductEditorScreen({super.key, this.product});

  final AdminProduct? product;

  @override
  ConsumerState<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends ConsumerState<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _mrp;
  late final TextEditingController _stock;
  late final TextEditingController _sku;
  late final TextEditingController _brand;

  late List<String> _images;
  late List<AdminVariant> _variants;
  String? _section;
  late bool _active;
  double _rating = 0;

  bool _saving = false;
  bool _uploading = false;
  int _uploadDone = 0;
  int _uploadTotal = 0;

  bool get _isNew => widget.product == null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
      text: p == null || p.price == 0 ? '' : _trimZeros(p.price),
    );
    _mrp = TextEditingController(text: p?.mrp == null ? '' : _trimZeros(p!.mrp!));
    _stock = TextEditingController(text: '${p?.stock ?? 0}');
    _sku = TextEditingController(text: p?.sku ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _images = List<String>.from(p?.images ?? const []);
    _variants = List<AdminVariant>.from(p?.variants ?? const []);
    _section = p?.category.isEmpty ?? true ? null : p!.category;
    _active = p?.active ?? true;
    _rating = p?.rating ?? 0;
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _mrp, _stock, _sku, _brand]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  // -------------------------------------------------------------------------
  // Photos
  // -------------------------------------------------------------------------

  Future<void> _addPhotos() async {
    final storage = ref.read(storageServiceProvider);
    // Checked before the picker opens: being told the account is not set up is
    // far better after choosing five photos than in place of uploading them.
    if (!storage.isConfigured) {
      showToast(
        context,
        const StorageNotConfiguredException().toString(),
        isError: true,
      );
      return;
    }

    final files = await storage.pickImages();
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadDone = 0;
      _uploadTotal = files.length;
    });

    try {
      // Uploaded one at a time, and each URL is added as it lands: if the
      // third of five fails, the first two are already on the form rather
      // than thrown away with the batch.
      for (var i = 0; i < files.length; i++) {
        final url = await storage.uploadProductImage(files[i]);
        if (!mounted) return;
        setState(() {
          _images.add(url);
          _uploadDone = i + 1;
        });
      }
      if (mounted) {
        showToast(
          context,
          '${files.length} photo${files.length == 1 ? '' : 's'} uploaded.',
        );
      }
    } catch (e) {
      if (mounted) showToast(context, 'Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(int index) {
    final url = _images[index];
    setState(() => _images.removeAt(index));
    // Only the reference goes. Deleting the file from Cloudinary needs a
    // signed call, which needs an API secret, which cannot live in a browser
    // app — so the orphan stays in the Media Library. See [StorageService].
    ref.read(storageServiceProvider).forgetImage(url);
  }

  void _makePrimary(int index) {
    setState(() {
      final url = _images.removeAt(index);
      _images.insert(0, url);
    });
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      showToast(context, 'Fix the highlighted fields first.', isError: true);
      return;
    }
    if (_section == null) {
      showToast(context, 'Pick a section for this product.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final service = ref.read(productServiceProvider);
    final price = double.parse(_price.text.trim());
    final mrpText = _mrp.text.trim();
    final mrp = mrpText.isEmpty ? null : double.tryParse(mrpText);

    final product = AdminProduct(
      id: widget.product?.id ?? '',
      name: _name.text.trim(),
      // The storefront reads the single `image` field, so the first photo is
      // the one it shows.
      image: _images.isEmpty ? '' : _images.first,
      images: _images,
      price: price,
      mrp: mrp,
      category: _section!,
      rating: _rating,
      description: _description.text.trim(),
      variants: _variants,
      stock: int.tryParse(_stock.text.trim()) ?? 0,
      active: _active,
      sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      createdAt: widget.product?.createdAt,
    );

    try {
      if (_isNew) {
        await service.create(product);
      } else {
        await service.update(product);
      }
      if (mounted) {
        showToast(context, _isNew ? 'Product added.' : 'Changes saved.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showToast(context, 'Could not save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this product?',
      message: '"${widget.product!.name}" will be removed from the catalog and '
          'will disappear from the app. Past orders are unaffected.',
    );
    if (!ok) return;
    await ref.read(productServiceProvider).delete(widget.product!.id);
    if (mounted) {
      showToast(context, 'Product deleted.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionsProvider).valueOrNull ?? const <StoreSection>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add product' : 'Edit product'),
        leading: const BackButton(),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Delete product',
              icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
              onPressed: _saving ? null : _delete,
            ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: _SaveBar(
        saving: _saving,
        isNew: _isNew,
        onSave: _saving ? null : _save,
        onCancel: _saving ? null : () => Navigator.of(context).pop(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _photosCard(),
                  const SizedBox(height: 16),
                  _basicsCard(sections),
                  const SizedBox(height: 16),
                  _pricingCard(),
                  const SizedBox(height: 16),
                  _variantsCard(),
                  const SizedBox(height: 16),
                  _visibilityCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cards
  // -------------------------------------------------------------------------

  Widget _photosCard() {
    return PanelCard(
      title: 'Photos',
      subtitle: 'The first photo is what shoppers see in the app',
      action: TextButton.icon(
        onPressed: _uploading ? null : _addPhotos,
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 19),
        label: const Text('Add photos'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_uploading) ...[
            // Counted per photo rather than per byte: the browser upload gives
            // no byte-level callback, and downscaled photos go up fast enough
            // that a file counter is the more useful number anyway.
            LinearProgressIndicator(
              value: _uploadTotal == 0 ? null : _uploadDone / _uploadTotal,
            ),
            const SizedBox(height: 6),
            Text(
              _uploadTotal == 1
                  ? 'Uploading photo…'
                  : 'Uploading photo '
                      '${(_uploadDone + 1).clamp(1, _uploadTotal)} '
                      'of $_uploadTotal…',
              style: const TextStyle(fontSize: 12, color: AdminColors.textGrey),
            ),
            const SizedBox(height: 14),
          ],
          if (_images.isEmpty)
            InkWell(
              onTap: _uploading ? null : _addPhotos,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AdminColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AdminColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 30,
                      color: AdminColors.textLight,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Click to add product photos',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AdminColors.textGrey,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'JPG or PNG · resized automatically before upload',
                      style: TextStyle(fontSize: 11.5, color: AdminColors.textLight),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < _images.length; i++)
                  _PhotoTile(
                    url: _images[i],
                    isPrimary: i == 0,
                    onRemove: () => _removePhoto(i),
                    onMakePrimary: i == 0 ? null : () => _makePrimary(i),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _basicsCard(List<StoreSection> sections) {
    return PanelCard(
      title: 'Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Product name *',
              hintText: 'Cotton Kurta – Navy',
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Every product needs a name'
                : null,
          ),
          const SizedBox(height: 14),
          _SectionPicker(
            sections: sections,
            value: _section,
            onChanged: (v) => setState(() => _section = v),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Fabric, fit, condition, warranty — whatever helps '
                  'someone decide.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _brand,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    hintText: 'HP, Levi\'s…',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sku,
                  decoration: const InputDecoration(
                    labelText: 'SKU / code',
                    hintText: 'Your own shelf code',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pricingCard() {
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final mrp = double.tryParse(_mrp.text.trim()) ?? 0;
    final discount = (mrp > price && mrp > 0)
        ? (((mrp - price) / mrp) * 100).round()
        : 0;

    return PanelCard(
      title: 'Price & stock',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Selling price *',
                    prefixText: '₹ ',
                  ),
                  validator: (v) {
                    final value = double.tryParse((v ?? '').trim());
                    if (value == null) return 'Enter a price';
                    if (value <= 0) return 'Price must be more than zero';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _mrp,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'MRP (before discount)',
                    prefixText: '₹ ',
                    helperText: 'Leave blank if there is no discount',
                  ),
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return null;
                    final value = double.tryParse(text);
                    if (value == null) return 'Enter a number';
                    final selling = double.tryParse(_price.text.trim()) ?? 0;
                    // An MRP at or below the selling price would show the
                    // shopper a struck-through number that is not a saving.
                    if (value <= selling) return 'MRP must be above the price';
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: AdminColors.successSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 18, color: AdminColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Shoppers see $discount% off — '
                      '${Money.format(mrp)} struck through, '
                      '${Money.format(price)} to pay.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AdminColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Stock on hand',
                    helperText: 'Alerts on the dashboard at '
                        '${AdminProduct.lowStockThreshold} or fewer',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Star rating shown in the app',
                      style: TextStyle(fontSize: 12, color: AdminColors.textGrey),
                    ),
                    Row(
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(),
                            // Tapping the star you are already on clears the
                            // rating, so a new product can honestly show none.
                            onPressed: () => setState(
                              () => _rating = _rating == star ? 0 : star.toDouble(),
                            ),
                            icon: Icon(
                              _rating >= star ? Icons.star : Icons.star_border,
                              size: 24,
                              color: _rating >= star
                                  ? AdminColors.orange
                                  : AdminColors.textLight,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _rating == 0 ? 'None' : _rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _variantsCard() {
    return PanelCard(
      title: 'Variants',
      subtitle: 'Sizes, colours, RAM tiers — optional',
      action: TextButton.icon(
        onPressed: () => setState(() {
          _variants = [
            ..._variants,
            AdminVariant(
              id: 'v${DateTime.now().microsecondsSinceEpoch}',
              title: '',
              price: double.tryParse(_price.text.trim()) ?? 0,
            ),
          ];
        }),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add variant'),
      ),
      child: _variants.isEmpty
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                color: AdminColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No variants. The product sells as a single option at the price '
                'above — which is right for most second-hand items.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AdminColors.textGrey,
                  height: 1.5,
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < _variants.length; i++)
                  _VariantRow(
                    key: ValueKey(_variants[i].id),
                    variant: _variants[i],
                    onChanged: (v) => setState(() => _variants[i] = v),
                    onRemove: () => setState(() => _variants.removeAt(i)),
                  ),
              ],
            ),
    );
  }

  Widget _visibilityCard() {
    return Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
        value: _active,
        onChanged: (v) => setState(() => _active = v),
        title: const Text(
          'Show in the app',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _active
              ? 'Customers can find and buy this product.'
              : 'Saved as a draft — hidden from the storefront.',
          style: const TextStyle(fontSize: 12.5, color: AdminColors.textGrey),
        ),
        secondary: Icon(
          _active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: _active ? AdminColors.success : AdminColors.textGrey,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.url,
    required this.isPrimary,
    required this.onRemove,
    this.onMakePrimary,
  });

  final String url;
  final bool isPrimary;
  final VoidCallback onRemove;
  final VoidCallback? onMakePrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPrimary ? AdminColors.primary : AdminColors.border,
                    width: isPrimary ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(3),
                child: ImageThumb(url: url, size: 122, radius: 9),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 15, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isPrimary)
            const Center(
              child: Pill(
                label: 'Main photo',
                color: AdminColors.primary,
                dense: true,
                icon: Icons.star,
              ),
            )
          else
            TextButton(
              onPressed: onMakePrimary,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                textStyle: const TextStyle(fontSize: 11.5),
              ),
              child: const Text('Make main'),
            ),
        ],
      ),
    );
  }
}

/// Section dropdown with an inline "create section" escape hatch, so adding a
/// product for a section that does not exist yet never dead-ends.
class _SectionPicker extends ConsumerWidget {
  const _SectionPicker({
    required this.sections,
    required this.value,
    required this.onChanged,
  });

  final List<StoreSection> sections;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = sections.map((s) => s.name).toList();
    // A product may already sit in a section that was since deleted or
    // renamed; keep its value selectable rather than silently blanking it.
    if (value != null && !names.contains(value)) names.insert(0, value!);

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Section *'),
            hint: const Text('Choose a section'),
            items: [
              for (final name in names)
                DropdownMenuItem(
                  value: name,
                  child: Row(
                    children: [
                      Icon(
                        sections
                                .where((s) => s.name == name)
                                .firstOrNull
                                ?.icon ??
                            Icons.help_outline,
                        size: 17,
                        color: AdminColors.textGrey,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: 'New section',
          icon: const Icon(Icons.add, size: 20),
          onPressed: () async {
            final name = await _promptSectionName(context);
            if (name == null || name.trim().isEmpty) return;
            final trimmed = name.trim();
            await ref.read(sectionServiceProvider).create(
                  StoreSection(
                    id: '',
                    name: trimmed,
                    sortOrder: sections.length,
                  ),
                );
            onChanged(trimmed);
            if (context.mounted) showToast(context, 'Section "$trimmed" created.');
          },
        ),
      ],
    );
  }

  Future<String?> _promptSectionName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Section name',
            hintText: 'Second-hand Monitors',
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _VariantRow extends StatefulWidget {
  const _VariantRow({
    super.key,
    required this.variant,
    required this.onChanged,
    required this.onRemove,
  });

  final AdminVariant variant;
  final ValueChanged<AdminVariant> onChanged;
  final VoidCallback onRemove;

  @override
  State<_VariantRow> createState() => _VariantRowState();
}

class _VariantRowState extends State<_VariantRow> {
  late final _title = TextEditingController(text: widget.variant.title);
  late final _price = TextEditingController(
    text: widget.variant.price == 0
        ? ''
        : _ProductEditorScreenState._trimZeros(widget.variant.price),
  );
  late final _qty = TextEditingController(
    text: widget.variant.quantityAvailable?.toString() ?? '',
  );

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _emit() {
    final qtyText = _qty.text.trim();
    widget.onChanged(
      widget.variant.copyWith(
        title: _title.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? widget.variant.price,
        quantityAvailable: qtyText.isEmpty ? null : int.tryParse(qtyText),
        clearQuantity: qtyText.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _title,
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(
                labelText: 'Option',
                hintText: 'M / 8GB RAM',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(labelText: 'Price', prefixText: '₹'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _qty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _emit(),
              decoration: const InputDecoration(labelText: 'Qty'),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: widget.variant.availableForSale
                ? 'In stock — tap to mark sold out'
                : 'Sold out — tap to mark available',
            child: IconButton(
              icon: Icon(
                widget.variant.availableForSale
                    ? Icons.check_circle
                    : Icons.remove_circle_outline,
                color: widget.variant.availableForSale
                    ? AdminColors.success
                    : AdminColors.textLight,
              ),
              onPressed: () => widget.onChanged(
                widget.variant.copyWith(
                  availableForSale: !widget.variant.availableForSale,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove variant',
            icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.isNew,
    required this.onSave,
    required this.onCancel,
  });

  final bool saving;
  final bool isNew;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.card,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onSave,
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 19),
                label: Text(isNew ? 'Add product' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
