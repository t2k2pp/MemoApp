import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_config.dart';
import '../providers/settings_provider.dart';

/// Settings screen for configuring AI providers
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AIConfig _config;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _geminiKeyController = TextEditingController();
  final TextEditingController _ollamaEndpointController = TextEditingController();
  final TextEditingController _lmStudioEndpointController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _geminiKeyController.dispose();
    _ollamaEndpointController.dispose();
    _lmStudioEndpointController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  void _loadConfig() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _config = settingsProvider.config;
    
    _geminiKeyController.text = _config.geminiApiKey ?? '';
    _ollamaEndpointController.text = _config.ollamaEndpoint ?? 'http://localhost:11434';
    _lmStudioEndpointController.text = _config.lmStudioEndpoint ?? 'http://localhost:1234';
    _modelNameController.text = _config.modelName ?? '';
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    final newConfig = AIConfig(
      provider: _config.provider,
      geminiApiKey: _geminiKeyController.text.trim().isEmpty 
          ? null 
          : _geminiKeyController.text.trim(),
      ollamaEndpoint: _ollamaEndpointController.text.trim().isEmpty
          ? null
          : _ollamaEndpointController.text.trim(),
      lmStudioEndpoint: _lmStudioEndpointController.text.trim().isEmpty
          ? null
          : _lmStudioEndpointController.text.trim(),
      modelName: _modelNameController.text.trim().isEmpty
          ? null
          : _modelNameController.text.trim(),
      enabled: _config.enabled,
    );

    await settingsProvider.updateConfig(newConfig);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('設定を保存しました')),
      );
    }
  }

  Future<void> _testConnection() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Save first to initialize the service
    await _saveConfig();
    
    if (context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await settingsProvider.testConnection();

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(success ? '接続成功' : '接続失敗'),
            content: Text(
              success
                  ? 'AIサービスに正常に接続できました'
                  : settingsProvider.errorMessage ?? '接続に失敗しました',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
            tooltip: '保存',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI Enable switch
            SwitchListTile(
              title: const Text('AI機能を有効にする'),
              subtitle: const Text('OCRとテキストリライト機能を使用'),
              value: _config.enabled,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(enabled: value);
                });
              },
            ),
            const Divider(),

            // Provider selection
            const Text(
              'AIプロバイダー',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            RadioListTile<AIProvider>(
              title: const Text('Gemini API'),
              subtitle: const Text('Google の Gemini API を使用'),
              value: AIProvider.gemini,
              groupValue: _config.provider,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(provider: value);
                });
              },
            ),

            RadioListTile<AIProvider>(
              title: const Text('Ollama'),
              subtitle: const Text('ローカルで動作する Ollama を使用'),
              value: AIProvider.ollama,
              groupValue: _config.provider,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(provider: value);
                });
              },
            ),

            RadioListTile<AIProvider>(
              title: const Text('LM Studio'),
              subtitle: const Text('ローカルで動作する LM Studio を使用'),
              value: AIProvider.lmStudio,
              groupValue: _config.provider,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(provider: value);
                });
              },
            ),

            const Divider(),
            const SizedBox(height: 16),

            // Provider-specific configuration
            _buildProviderConfig(),

            const SizedBox(height: 24),

            // Test connection button
            ElevatedButton.icon(
              onPressed: _config.enabled ? _testConnection : null,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('接続テスト'),
            ),

            const SizedBox(height: 16),

            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'ヒント',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gemini API: Google AI Studio で API キーを取得してください\n'
                      'Ollama: ローカルで ollama を起動し、llava モデルをインストールしてください\n'
                      'LM Studio: ビジョンモデルをロードし、サーバーを起動してください',
                      style: TextStyle(fontSize: 12),
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

  Widget _buildProviderConfig() {
    switch (_config.provider) {
      case AIProvider.gemini:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gemini API 設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _geminiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'AIza...',
                border: OutlineInputBorder(),
                helperText: 'Google AI Studio で取得した API キー',
              ),
              validator: (value) {
                if (_config.enabled && (value == null || value.trim().isEmpty)) {
                  return 'API キーを入力してください';
                }
                return null;
              },
            ),
          ],
        );

      case AIProvider.ollama:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ollama 設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ollamaEndpointController,
              decoration: const InputDecoration(
                labelText: 'エンドポイント URL',
                hintText: 'http://localhost:11434',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_config.enabled && (value == null || value.trim().isEmpty)) {
                  return 'エンドポイント URL を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelNameController,
              decoration: const InputDecoration(
                labelText: 'モデル名',
                hintText: 'llava',
                border: OutlineInputBorder(),
                helperText: 'ビジョンモデル (例: llava, bakllava)',
              ),
            ),
          ],
        );

      case AIProvider.lmStudio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LM Studio 設定',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lmStudioEndpointController,
              decoration: const InputDecoration(
                labelText: 'エンドポイント URL',
                hintText: 'http://localhost:1234',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_config.enabled && (value == null || value.trim().isEmpty)) {
                  return 'エンドポイント URL を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelNameController,
              decoration: const InputDecoration(
                labelText: 'モデル名',
                hintText: 'local-model',
                border: OutlineInputBorder(),
                helperText: 'LM Studio でロードしたモデル名',
              ),
            ),
          ],
        );
    }
  }
}
