import 'package:flutter/material.dart';

import '../app_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _url = TextEditingController();
  String? _probe;
  bool _probing = false;
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    _url.text = AppScope.of(context).baseUrl;
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_probe != null) Text(_probe!),
                if (state.banner != null)
                  Text(
                    state.banner!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _probing
                          ? null
                          : () async {
                              setState(() => _probing = true);
                              final message = await state.probe(_url.text);
                              if (!mounted) return;
                              setState(() {
                                _probing = false;
                                _probe = message;
                              });
                            },
                      child: Text(_probing ? '探测中…' : '探测'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () async {
                        final ok = await state.confirmBaseUrl(_url.text);
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: state.logout,
                  child: const Text('退出登录'),
                ),
                const SizedBox(height: 8),
                Text(
                  '登录令牌只保存在本机钥匙串，不会写入仓库或日志。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
