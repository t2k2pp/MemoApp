import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memo_provider.dart';
import '../widgets/memo_card.dart';
import '../widgets/tag_chip.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

/// Home screen displaying all memos in a grid
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor(BuildContext context, String? memoId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(memoId: memoId),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String memoId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: Text(title.isEmpty ? 'このメモを削除しますか?' : '"$title"を削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MemoProvider>(context, listen: false)
                  .deleteMemo(memoId);
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showTagFilterDialog(BuildContext context) {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    final allTags = memoProvider.allTags;
    final selectedTags = List<String>.from(memoProvider.selectedTags);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('タグでフィルター'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allTags.length,
              itemBuilder: (context, index) {
                final tag = allTags[index];
                final isSelected = selectedTags.contains(tag);
                return CheckboxListTile(
                  title: Text(tag),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedTags.add(tag);
                      } else {
                        selectedTags.remove(tag);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                memoProvider.setSelectedTags([]);
                Navigator.pop(context);
              },
              child: const Text('クリア'),
            ),
            TextButton(
              onPressed: () {
                memoProvider.setSelectedTags(selectedTags);
                Navigator.pop(context);
              },
              child: const Text('適用'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '検索...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<MemoProvider>().setSearchQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (query) {
                      context.read<MemoProvider>().setSearchQuery(query);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showTagFilterDialog(context),
                ),
              ],
            ),
          ),

          // Selected tags display
          Consumer<MemoProvider>(
            builder: (context, memoProvider, child) {
              if (memoProvider.selectedTags.isEmpty) {
                return const SizedBox();
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...memoProvider.selectedTags.map((tag) {
                      return TagChip(
                        tag: tag,
                        selected: true,
                        onDeleted: () {
                          final updated = memoProvider.selectedTags
                              .where((t) => t != tag)
                              .toList();
                          memoProvider.setSelectedTags(updated);
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // Memos grid
          Expanded(
            child: Consumer<MemoProvider>(
              builder: (context, memoProvider, child) {
                if (memoProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final memos = memoProvider.memos;

                if (memos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'メモがありません',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '右下の + ボタンで新しいメモを作成',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    return MemoCard(
                      memo: memo,
                      onTap: () => _openEditor(context, memo.id),
                      onLongPress: () =>
                          _showDeleteDialog(context, memo.id, memo.title),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final memoProvider = Provider.of<MemoProvider>(context, listen: false);
          final memo = await memoProvider.createMemo();
          if (context.mounted) {
            _openEditor(context, memo.id);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
