import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memo.dart';
import '../providers/memo_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/handwriting_canvas.dart';
import '../widgets/tag_chip.dart';

/// Editor screen for creating and editing memos
class EditorScreen extends StatefulWidget {
  final String? memoId;

  const EditorScreen({super.key, this.memoId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late Memo _memo;
  bool _isNew = true;
  bool _isTextMode = true;
  bool _enableTouchDrawing = false;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _rewriteInstructionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  @override
  void dispose() {
    _saveMemo();
    _titleController.dispose();
    _contentController.dispose();
    _rewriteInstructionController.dispose();
    super.dispose();
  }

  void _loadMemo() {
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);
    
    if (widget.memoId != null) {
      final existingMemo = memoProvider.allMemos
          .where((m) => m.id == widget.memoId)
          .firstOrNull;
      if (existingMemo != null) {
        _memo = existingMemo;
        _isNew = false;
        _titleController.text = _memo.title;
        _contentController.text = _memo.content;
        return;
      }
    }
    
    // Create new memo if not found
    _memo = Memo(id: widget.memoId ?? DateTime.now().toString());
  }

  void _saveMemo() {
    _memo.title = _titleController.text;
    _memo.content = _contentController.text;
    Provider.of<MemoProvider>(context, listen: false).updateMemo(_memo);
  }

  void _performOCR() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final memoProvider = Provider.of<MemoProvider>(context, listen: false);

    if (settingsProvider.activeService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIサービスが設定されていません')),
      );
      return;
    }

    if (_memo.strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('手書きメモがありません')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final ocrText = await memoProvider.performOCR(_memo, settingsProvider.activeService!);

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog

      if (ocrText != null && ocrText.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('OCR結果'),
            content: SingleChildScrollView(
              child: Text(ocrText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テキストを抽出できませんでした')),
        );
      }
    }
  }

  void _showRewriteDialog() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settingsProvider.activeService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIサービスが設定されていません')),
      );
      return;
    }

    final selectedText = _contentController.selection.textInside(_contentController.text);
    final textToRewrite = selectedText.isNotEmpty ? selectedText : _contentController.text;

    if (textToRewrite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リライトするテキストがありません')),
      );
      return;
    }

    _rewriteInstructionController.clear();
    String? rewrittenText;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('AIリライト'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('元のテキスト:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(textToRewrite),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rewriteInstructionController,
                  decoration: const InputDecoration(
                    labelText: '指示',
                    hintText: '例: 要約して、丁寧な表現に',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (rewrittenText != null) ...[
                  const Text('リライト結果:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(rewrittenText!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            if (rewrittenText == null)
              ElevatedButton(
                onPressed: () async {
                  if (_rewriteInstructionController.text.isEmpty) {
                    return;
                  }

                  setState(() => isLoading = true);

                  final memoProvider = Provider.of<MemoProvider>(context, listen: false);
                  final result = await memoProvider.rewriteText(
                    textToRewrite,
                    _rewriteInstructionController.text,
                    settingsProvider.activeService!,
                  );

                  setState(() {
                    isLoading = false;
                    rewrittenText = result;
                  });
                },
                child: const Text('生成'),
              )
            else ...[
              TextButton(
                onPressed: () {
                  // Append to content
                  setState(() {
                    _contentController.text += '\n\n$rewrittenText';
                  });
                  Navigator.pop(context);
                },
                child: const Text('挿入'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Show confirmation
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認'),
                      content: const Text('元のテキストを置き換えますか?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedText.isNotEmpty) {
                              // Replace selection
                              final selection = _contentController.selection;
                              _contentController.text = _contentController.text.replaceRange(
                                selection.start,
                                selection.end,
                                rewrittenText!,
                              );
                            } else {
                              // Replace all
                              _contentController.text = rewrittenText!;
                            }
                            Navigator.pop(context); // Close confirmation
                            Navigator.pop(context); // Close rewrite dialog
                          },
                          child: const Text('置き換え'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('置き換え'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _saveMemo();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('メモ編集'),
          actions: [
            if (!_isTextMode)
              IconButton(
                icon: const Icon(Icons.text_fields),
                onPressed: _performOCR,
                tooltip: '手書きを認識',
              ),
            if (_isTextMode)
              IconButton(
                icon: const Icon(Icons.auto_fix_high),
                onPressed: _showRewriteDialog,
                tooltip: 'AIリライト',
              ),
          ],
        ),
        body: Column(
          children: [
            // Mode toggle
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('テキスト'),
                    selected: _isTextMode,
                    onSelected: (selected) {
                      setState(() => _isTextMode = true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('手書き'),
                    selected: !_isTextMode,
                    onSelected: (selected) {
                      setState(() => _isTextMode = false);
                    },
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: _isTextMode
                  ? _buildTextEditor()
                  : _buildHandwritingEditor(),
            ),

            // Tags
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: TagInput(
                tags: _memo.tags,
                onTagsChanged: (tags) {
                  setState(() {
                    _memo.tags = tags;
                  });
                },
                suggestions: Provider.of<MemoProvider>(context).allTags,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'タイトル',
              border: InputBorder.none,
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (_) => _saveMemo(),
          ),
          const Divider(),
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '内容',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
              maxLines: null,
              expands: true,
              onChanged: (_) => _saveMemo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandwritingEditor() {
    return HandwritingCanvas(
      strokes: _memo.strokes,
      onStrokesChanged: (strokes) {
        setState(() {
          _memo.strokes = strokes;
        });
        _saveMemo();
      },
      enableTouchDrawing: _enableTouchDrawing,
      onTouchModeToggleRequested: () {
        setState(() {
          _enableTouchDrawing = !_enableTouchDrawing;
        });
      },
    );
  }
}
