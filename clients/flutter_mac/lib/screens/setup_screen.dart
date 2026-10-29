import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../config/defaults.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _url =
      TextEditingController(text: kDefaultBaseUrl);
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

  Future<void> _probeUrl() async {
    setState(() {
      _probing = true;
      _probe = null;
    });
    final message = await AppScope.of(context).probe(_url.text);
    if (!mounted) return;
    setState(() {
      _probing = false;
      _probe = message;
    });
  }

  Future<void> _continue() async {
    await AppScope.of(context).confirmBaseUrl(_url.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('连接 Octop',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text('确认服务器地址。默认指向学校 hp02。'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _url,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: kDefaultBaseUrl,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _continue(),
                  ),
                  if (_probe != null) ...[
                    const SizedBox(height: 12),
                    Text(_probe!),
                  ],
                  if (state.banner != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.banner!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _probing ? null : _probeUrl,
                        child: Text(_probing ? '探测中…' : '探测'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: state.busy ? null : _continue,
                        child: const Text('继续'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
