import 'package:flutter/material.dart';

/// Widget for displaying memo tags as chips
class TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final bool selected;

  const TagChip({
    super.key,
    required this.tag,
    this.onDeleted,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: FilterChip(
        label: Text(tag),
        selected: selected,
        onSelected: onTap != null ? (_) => onTap!() : null,
        onDeleted: onDeleted,
        deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 16) : null,
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? Colors.blue[900] : Colors.black87,
        ),
      ),
    );
  }
}

/// Widget for inputting new tags
class TagInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final List<String> suggestions;

  const TagInput({
    super.key,
    required this.tags,
    required this.onTagsChanged,
    this.suggestions = const [],
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;
    if (widget.tags.contains(trimmedTag)) return;

    widget.onTagsChanged([...widget.tags, trimmedTag]);
    _controller.clear();
  }

  void _removeTag(String tag) {
    final updatedTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(updatedTags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display existing tags
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 4,
            children: widget.tags.map((tag) {
              return TagChip(
                tag: tag,
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),

        // Tag input field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'タグを追加',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onSubmitted: _addTag,
              ),
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addTag(_controller.text),
              ),
          ],
        ),

        // Suggestions
        if (widget.suggestions.isNotEmpty && _focusNode.hasFocus)
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                if (widget.tags.contains(suggestion)) return const SizedBox();
                
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                  leading: const Icon(Icons.label, size: 16),
                  onTap: () {
                    _addTag(suggestion);
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
