import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/message.dart';
import '../state/app_state.dart';
import 'settings_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 280, child: _Sidebar(state: state)),
          const VerticalDivider(width: 1),
          Expanded(child: _ChatPane(state: state)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Octop',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: '设置',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AppScope(
                            state: AppScope.of(context),
                            child: const SettingsScreen(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            _ProjectSpace(state: state),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  const Expanded(child: Text('对话')),
                  IconButton(
                    tooltip: '新对话',
                    onPressed: state.newThread,
                    icon: const Icon(Icons.add_comment_outlined, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final thread in state.threads)
                    ListTile(
                      dense: true,
                      selected: thread.threadId == state.activeThreadId,
                      title: Text(
                        thread.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => state.openThread(thread.threadId),
                    ),
                  if (state.threads.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('还没有会话'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              title:
                  Text(state.user?.displayName ?? state.user?.username ?? ''),
              subtitle: const Text('退出'),
              onTap: state.logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectSpace extends StatelessWidget {
  const _ProjectSpace({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: state.toggleProjects,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(child: Text('项目空间')),
                Icon(
                  state.projectsCollapsed
                      ? Icons.chevron_right
                      : Icons.expand_more,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!state.projectsCollapsed) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              onPressed: () => _createProject(context),
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('新建项目'),
            ),
          ),
          const SizedBox(height: 8),
          if (state.projects.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('暂无项目，点击上方新建'),
            )
          else
            for (final project in state.projects)
              ListTile(
                dense: true,
                selected: project.id == state.activeProjectId,
                leading: const Icon(Icons.folder_outlined, size: 18),
                title: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: '删除',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => state.deleteProject(project.id),
                ),
                onTap: () => state.selectProject(project.id),
              ),
        ],
      ],
    );
  }

  Future<void> _createProject(BuildContext context) async {
    final name = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新建项目'),
          content: TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(hintText: '项目名称'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(name.text),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
    name.dispose();
    if (created != null) await state.createProject(created);
  }
}

class _ChatPane extends StatefulWidget {
  const _ChatPane({required this.state});

  final AppState state;

  @override
  State<_ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<_ChatPane> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({bool retry = false}) async {
    final text = retry ? widget.state.lastUserText ?? '' : _input.text;
    if (!retry) _input.clear();
    await widget.state.sendMessage(text, retry: retry);
    if (!mounted || !_scroll.hasClients) return;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final agent = state.selectedAgent;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  agent == null ? '对话' : agent.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (state.agents.length > 1)
                DropdownButton<String>(
                  value: agent?.agentId,
                  items: [
                    for (final item in state.agents)
                      DropdownMenuItem(
                        value: item.agentId,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: (id) {
                    if (id == null) return;
                    for (final item in state.agents) {
                      if (item.agentId == id) {
                        state.selectAgent(item);
                        break;
                      }
                    }
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.messages.isEmpty
              ? const Center(child: Text('给 main 发一条消息'))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(20),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    if (message.content.isEmpty &&
                        message.isStreaming != true) {
                      return const SizedBox.shrink();
                    }
                    final mine = message.role == MessageRole.user;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 640),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          message.content.isEmpty ? '…' : message.content,
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (state.chatError != null || state.banner != null)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(state.chatError ?? state.banner!)),
                  TextButton(
                    onPressed: state.sending ? null : () => _send(retry: true),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '输入消息',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: state.sending ? null : (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: state.sending ? null : _send,
                child: Text(state.sending ? '发送中' : '发送'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
