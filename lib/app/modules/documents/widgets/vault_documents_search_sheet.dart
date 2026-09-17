import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/documents_controller.dart';

/// Owns its [TextEditingController] so dispose cannot race sheet rebuilds.
class VaultDocumentsSearchSheet extends StatefulWidget {
  const VaultDocumentsSearchSheet({
    super.key,
    required this.source,
    required this.hintText,
    required this.emptyLabel,
    required this.onOpenItem,
  });

  final List<DocumentItem> source;
  final String hintText;
  final String emptyLabel;
  final ValueChanged<DocumentItem> onOpenItem;

  @override
  State<VaultDocumentsSearchSheet> createState() =>
      _VaultDocumentsSearchSheetState();
}

class _VaultDocumentsSearchSheetState extends State<VaultDocumentsSearchSheet> {
  late final TextEditingController _searchCtrl;
  late final RxString _query;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _query = ''.obs;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = Get.locale?.languageCode == 'sw';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => _query.value = v.trim().toLowerCase(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  if (_query.value.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: isSw ? 'Futa' : 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _query.value = '';
                    },
                  );
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Obx(() {
                final q = _query.value;
                final filtered = q.isEmpty
                    ? widget.source
                    : widget.source
                        .where(
                          (d) =>
                              d.name.toLowerCase().contains(q) ||
                              d.size.toLowerCase().contains(q),
                        )
                        .toList();
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(widget.emptyLabel),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = filtered[index];
                    return ListTile(
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(item.size),
                      trailing: item.isDirectory
                          ? null
                          : const Icon(Icons.more_vert),
                      onTap: () => widget.onOpenItem(item),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
