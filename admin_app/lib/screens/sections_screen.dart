import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../models/store_section.dart';
import '../providers/admin_providers.dart';
import '../services/storage_service.dart';
import '../services/section_service.dart';
import '../theme/admin_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'admin_shell.dart';

/// Manage the store's sections — what the app shows as category tiles.
class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsProvider);
    final products = ref.watch(productsProvider).valueOrNull ?? const <AdminProduct>[];

    return sectionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorPanel(
        error: e,
        onRetry: () => ref.invalidate(sectionsProvider),
      ),
      data: (sections) => AdminPage(
        children: [
          PageHeader(
            title: 'Sections',
            subtitle: 'The categories shoppers browse in the app',
            actions: [
              FilledButton.icon(
                onPressed: () => _edit(context, ref, null, sections.length),
                icon: const Icon(Icons.add, size: 19),
                label: const Text('Add section'),
              ),
            ],
          ),
          if (sections.isEmpty)
            Card(
              child: EmptyState(
                icon: Icons.category_outlined,
                title: 'No sections yet',
                message: 'Sections group your products — Clothes, Second-hand '
                    'Laptops, and so on. Add one to get started.',
                action: FilledButton.icon(
                  onPressed: () => _edit(context, ref, null, 0),
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Add section'),
                ),
              ),
            )
          else ...[
            const _ReorderHint(),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: sections.length,
                onReorder: (oldIndex, newIndex) async {
                  final reordered = [...sections];
                  if (newIndex > oldIndex) newIndex -= 1;
                  reordered.insert(newIndex, reordered.removeAt(oldIndex));
                  await ref.read(sectionServiceProvider).reorder(reordered);
                },
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final count = products
                      .where((p) => p.category == section.name)
                      .length;
                  final value = products
                      .where((p) => p.category == section.name)
                      .fold<double>(0, (total, p) => total + p.price * p.stock);
                  return _SectionRow(
                    key: ValueKey(section.id),
                    index: index,
                    section: section,
                    productCount: count,
                    stockValue: value,
                    onEdit: () => _edit(context, ref, section, sections.length),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    StoreSection? section,
    int sectionCount,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SectionDialog(section: section, nextSortOrder: sectionCount),
    );
  }
}

class _ReorderHint extends StatelessWidget {
  const _ReorderHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AdminColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.drag_indicator, size: 18, color: AdminColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Drag the handle to reorder. This is the order sections appear in '
              'the app.',
              style: TextStyle(fontSize: 12.5, color: AdminColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends ConsumerWidget {
  const _SectionRow({
    super.key,
    required this.index,
    required this.section,
    required this.productCount,
    required this.stockValue,
    required this.onEdit,
  });

  final int index;
  final StoreSection section;
  final int productCount;
  final double stockValue;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (index > 0) const Divider(height: 1),
        InkWell(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 20,
                      color: AdminColors.textLight,
                    ),
                  ),
                ),
                if (section.imageUrl != null)
                  ImageThumb(url: section.imageUrl, size: 46, radius: 11)
                else
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AdminColors.primarySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(section.icon, color: AdminColors.primary, size: 22),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              section.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!section.active) ...[
                            const SizedBox(width: 8),
                            const Pill(
                              label: 'Hidden',
                              color: AdminColors.textGrey,
                              dense: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        productCount == 0
                            ? 'No products yet'
                            : '$productCount product${productCount == 1 ? '' : 's'} · '
                                '${Money.compact(stockValue)} of stock',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AdminColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'View products in this section',
                  icon: const Icon(Icons.inventory_2_outlined, size: 19),
                  onPressed: () {
                    ref.read(productSectionFilterProvider.notifier).state =
                        section.name;
                    ref.read(productSearchProvider.notifier).state = '';
                    ref.read(navIndexProvider.notifier).state = 2;
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 19,
                    color: AdminColors.textGrey,
                  ),
                  onSelected: (value) async {
                    final service = ref.read(sectionServiceProvider);
                    switch (value) {
                      case 'edit':
                        onEdit();
                      case 'toggle':
                        await service.setActive(section.id, !section.active);
                      case 'delete':
                        // A section holding products cannot be deleted — say so
                        // and offer the way forward, rather than a confirm
                        // button that is certain to fail.
                        if (productCount > 0) {
                          if (!context.mounted) return;
                          showToast(
                            context,
                            '"${section.name}" still holds $productCount '
                            '${productCount == 1 ? 'product' : 'products'}. '
                            'Move them to another section first.',
                            isError: true,
                          );
                          return;
                        }
                        final ok = await confirmDialog(
                          context,
                          title: 'Delete "${section.name}"?',
                          message: 'The section will be removed from the app.',
                        );
                        if (!ok) return;
                        try {
                          await service.delete(section);
                          if (context.mounted) {
                            showToast(context, 'Section deleted.');
                          }
                        } on SectionNotEmptyException catch (e) {
                          // The count above is a snapshot; a product could have
                          // been filed here in the meantime.
                          if (context.mounted) {
                            showToast(context, e.toString(), isError: true);
                          }
                        }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(section.active ? 'Hide from app' : 'Show in app'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AdminColors.danger),
                      ),
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
}

/// Create or rename a section, pick its icon, and optionally give it a photo.
class _SectionDialog extends ConsumerStatefulWidget {
  const _SectionDialog({required this.section, required this.nextSortOrder});

  final StoreSection? section;
  final int nextSortOrder;

  @override
  ConsumerState<_SectionDialog> createState() => _SectionDialogState();
}

class _SectionDialogState extends ConsumerState<_SectionDialog> {
  late final _name = TextEditingController(text: widget.section?.name ?? '');
  late String _iconKey = widget.section?.iconKey ?? 'category';
  late String? _imageUrl = widget.section?.imageUrl;
  late bool _active = widget.section?.active ?? true;
  bool _saving = false;
  bool _uploading = false;

  bool get _isNew => widget.section == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final storage = ref.read(storageServiceProvider);
    if (!storage.isConfigured) {
      showToast(
        context,
        const StorageNotConfiguredException().toString(),
        isError: true,
      );
      return;
    }
    final file = await storage.pickImage();
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await storage.uploadSectionImage(file);
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) showToast(context, 'Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showToast(context, 'Give the section a name.', isError: true);
      return;
    }

    setState(() => _saving = true);
    final service = ref.read(sectionServiceProvider);
    try {
      if (_isNew) {
        await service.create(
          StoreSection(
            id: '',
            name: name,
            iconKey: _iconKey,
            imageUrl: _imageUrl,
            sortOrder: widget.nextSortOrder,
            active: _active,
          ),
        );
        if (mounted) showToast(context, 'Section created.');
      } else {
        final existing = widget.section!;
        var moved = 0;
        // Renaming has to carry the products across, since they reference the
        // section by name. Do that first, then save the rest of the edits.
        if (name != existing.name) {
          moved = await service.rename(existing, name);
        }
        await service.update(
          existing.copyWith(
            name: name,
            iconKey: _iconKey,
            imageUrl: _imageUrl,
            clearImage: _imageUrl == null,
            active: _active,
          ),
        );
        if (mounted) {
          showToast(
            context,
            moved > 0
                ? 'Section renamed. $moved product${moved == 1 ? '' : 's'} moved with it.'
                : 'Section updated.',
          );
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showToast(context, 'Could not save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? 'New section' : 'Edit section'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Section name',
                  hintText: 'Second-hand Monitors',
                ),
              ),
              if (!_isNew) ...[
                const SizedBox(height: 8),
                const Text(
                  'Renaming moves every product in this section to the new name '
                  'automatically.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AdminColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Icon',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in SectionIcons.keys)
                    InkWell(
                      onTap: () => setState(() => _iconKey = key),
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _iconKey == key
                              ? AdminColors.primary
                              : AdminColors.background,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: _iconKey == key
                                ? AdminColors.primary
                                : AdminColors.border,
                          ),
                        ),
                        child: Icon(
                          SectionIcons.resolve(key),
                          size: 20,
                          color: _iconKey == key
                              ? Colors.white
                              : AdminColors.textGrey,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (_imageUrl != null)
                    ImageThumb(url: _imageUrl, size: 56, radius: 11)
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AdminColors.background,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: AdminColors.textLight,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Banner photo (optional)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Shown instead of the icon where the app has room.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AdminColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _uploading ? null : _pickImage,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                              ),
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_outlined, size: 17),
                              label: Text(_imageUrl == null ? 'Upload' : 'Replace'),
                            ),
                            if (_imageUrl != null) ...[
                              const SizedBox(width: 14),
                              TextButton(
                                onPressed: () => setState(() => _imageUrl = null),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30),
                                  foregroundColor: AdminColors.danger,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text(
                  'Show in the app',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isNew ? 'Create section' : 'Save'),
        ),
      ],
    );
  }
}
