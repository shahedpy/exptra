import 'package:flutter/material.dart';
import 'app_ui.dart';

class MasterDataList<T> extends StatefulWidget {
  final String title;
  final String singular;
  final String emptyMessage;
  final IconData icon;
  final List<T> items;
  final bool loading;
  final String Function(T) idOf;
  final String Function(T) nameOf;
  final String? Function(T)? subtitleOf;
  final Color? Function(T)? colorOf;
  final VoidCallback onAdd;
  final ValueChanged<T> onEdit;
  final ValueChanged<T> onDelete;
  final ReorderCallback onReorder;
  const MasterDataList({
    super.key,
    required this.title,
    required this.singular,
    required this.emptyMessage,
    required this.icon,
    required this.items,
    required this.loading,
    required this.idOf,
    required this.nameOf,
    this.subtitleOf,
    this.colorOf,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  State<MasterDataList<T>> createState() => _MasterDataListState<T>();
}

class _MasterDataListState<T> extends State<MasterDataList<T>> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.items
        .where(
          (x) => widget.nameOf(x).toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final scheme = Theme.of(context).colorScheme;
    Widget row(T item, int index, {required bool reorder}) => Card(
      key: ValueKey(widget.idOf(item)),
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: widget.colorOf == null
            ? Icon(widget.icon, color: scheme.primary)
            : CircleAvatar(
                radius: 14,
                backgroundColor:
                    widget.colorOf!(item) ?? scheme.primaryContainer,
              ),
        title: Text(
          widget.nameOf(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: widget.subtitleOf == null
            ? null
            : Text(widget.subtitleOf!(item) ?? ''),
        onTap: () => widget.onEdit(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit ${widget.singular}',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => widget.onEdit(item),
            ),
            IconButton(
              tooltip: 'Delete ${widget.singular}',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => widget.onDelete(item),
            ),
            if (reorder)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle_rounded, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search ${widget.title.toLowerCase()}',
              ),
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: widget.onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text('Add ${widget.singular}'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.loading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.items.isEmpty
                  ? AppEmptyState(
                      title: 'No ${widget.title.toLowerCase()} yet',
                      message: widget.emptyMessage,
                      actionLabel: 'Add ${widget.singular}',
                      onAction: widget.onAdd,
                    )
                  : visible.isEmpty
                  ? const AppEmptyState(
                      title: 'No matches',
                      message: 'Try another search.',
                    )
                  : query.isNotEmpty
                  ? ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) => row(visible[i], i, reorder: false),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: visible.length,
                      onReorderItem: widget.onReorder,
                      itemBuilder: (_, i) => row(visible[i], i, reorder: true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
