import 'package:flutter/foundation.dart';

import '../config/defaults.dart';
import '../models/agent.dart';
import '../models/message.dart';
import '../models/project.dart';
import '../models/thread_summary.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_gate.dart';
import '../services/base_url.dart';
import '../services/chat_frames.dart';
import '../services/chat_socket.dart';
import '../services/credential_store.dart';
import '../services/project_repository.dart';

class AppState extends ChangeNotifier {
  AppState({
    required CredentialStore store,
    HttpTransport? transport,
    ChatConnector? connect,
    ProjectRepository? projects,
  })  : _store = store,
        _transport = transport ?? HttpTransportClient(),
        _connect = connect ?? connectLiveChat,
        _projects = projects ?? ProjectRepository(store) {
    _client = ApiClient(baseUrl: kDefaultBaseUrl, transport: _transport);
  }

  static const _baseUrlKey = 'octop.base_url';
  static const _confirmedKey = 'octop.base_url_confirmed';
  static const _tokenKey = 'octop.access_token';

  final CredentialStore _store;
  final HttpTransport _transport;
  final ChatConnector _connect;
  final ProjectRepository _projects;

  late ApiClient _client;
  ChatLink? _socket;

  bool ready = false;
  bool _loadStarted = false;
  bool busy = false;
  String? banner;

  String baseUrl = kDefaultBaseUrl;
  bool baseUrlConfirmed = false;
  String? token;
  User? user;

  List<Project> projects = const [];
  bool projectsCollapsed = false;
  String? activeProjectId;

  List<Agent> agents = const [];
  Agent? selectedAgent;
  List<ThreadSummary> threads = const [];
  String? activeThreadId;
  List<ChatMessage> messages = const [];
  bool sending = false;
  String? chatError;
  String? lastUserText;

  bool get isAuthenticated =>
      token != null && token!.trim().isNotEmpty && user != null;

  Future<void> load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    try {
      final saved = await _store.read(_baseUrlKey);
      final normalized = saved == null ? null : normalizeBaseUrl(saved);
      baseUrl = normalized ?? kDefaultBaseUrl;
      baseUrlConfirmed = (await _store.read(_confirmedKey)) == '1';
      token = await _store.read(_tokenKey);
      _client = ApiClient(
        baseUrl: baseUrl,
        transport: _transport,
        token: token,
      );
      final space = await _projects.load();
      projects = space.projects;
      projectsCollapsed = space.collapsed;
      activeProjectId = space.activeId;
      if (baseUrlConfirmed && token != null && token!.isNotEmpty) {
        try {
          user = await _client.me();
          await _loadAgents();
        } on UnauthenticatedException {
          await _clearSession();
        } on ApiException catch (error) {
          if (error.isUnauthorized) {
            await _clearSession();
          } else {
            banner = error.message;
          }
        }
      }
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<String?> probe([String? raw]) async {
    final origin = normalizeBaseUrl(raw ?? baseUrl);
    if (origin == null) return 'Base URL 无效';
    final probeClient = ApiClient(baseUrl: origin, transport: _transport);
    try {
      final health = await probeClient.health();
      final version = health.version;
      if (version == null || version.isEmpty) return '服务可达';
      return '服务可达（$version）';
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<bool> confirmBaseUrl(String raw) async {
    final origin = normalizeBaseUrl(raw);
    if (origin == null) {
      banner = 'Base URL 无效';
      notifyListeners();
      return false;
    }
    final changed = origin != baseUrl;
    baseUrl = origin;
    baseUrlConfirmed = true;
    await _store.write(_baseUrlKey, origin);
    await _store.write(_confirmedKey, '1');
    if (changed) {
      await _clearSession();
    }
    _client = ApiClient(
      baseUrl: baseUrl,
      transport: _transport,
      token: token,
    );
    banner = null;
    notifyListeners();
    return true;
  }

  Future<void> editBaseUrl() async {
    baseUrlConfirmed = false;
    banner = null;
    await _store.delete(_confirmedKey);
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    busy = true;
    banner = null;
    notifyListeners();
    try {
      final session = await _client.login(
        username: username.trim(),
        password: password,
      );
      token = session.token;
      user = session.user;
      await _store.write(_tokenKey, session.token);
      _client.token = session.token;
      await _loadAgents();
      return true;
    } on ApiException catch (error) {
      banner = error.message;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _client.logout();
    } on ApiException {
      // Local sign-out still proceeds when the server is unreachable.
    }
    await _clearSession();
    messages = const [];
    threads = const [];
    agents = const [];
    selectedAgent = null;
    notifyListeners();
  }

  Future<void> createProject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final space = await _projects.create(trimmed);
    _applySpace(space);
  }

  Future<void> selectProject(String id) async {
    _applySpace(await _projects.select(id));
  }

  Future<void> deleteProject(String id) async {
    _applySpace(await _projects.delete(id));
  }

  Future<void> toggleProjects() async {
    _applySpace(await _projects.setCollapsed(!projectsCollapsed));
  }

  Future<void> selectAgent(Agent agent) async {
    selectedAgent = agent;
    activeThreadId = null;
    messages = const [];
    chatError = null;
    notifyListeners();
    await refreshThreads();
  }

  Future<void> refreshThreads() async {
    final agent = selectedAgent;
    if (agent == null) return;
    try {
      threads = await _client.listThreads(agent.agentId);
      banner = null;
    } on ApiException catch (error) {
      banner = error.message;
      if (error.isUnauthorized) await _clearSession();
    }
    notifyListeners();
  }

  Future<void> openThread(String threadId) async {
    final agent = selectedAgent;
    if (agent == null) return;
    activeThreadId = threadId;
    chatError = null;
    notifyListeners();
    try {
      messages = await _client.history(agent.agentId, threadId);
    } on ApiException catch (error) {
      chatError = error.message;
      if (error.isUnauthorized) await _clearSession();
    }
    notifyListeners();
  }

  Future<void> newThread() async {
    final agent = selectedAgent;
    if (agent == null) return;
    try {
      final threadId = await _client.createThread(agent.agentId);
      activeThreadId = threadId;
      messages = const [];
      chatError = null;
      await refreshThreads();
    } on ApiException catch (error) {
      chatError = error.message;
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text, {bool retry = false}) async {
    final agent = selectedAgent;
    final trimmed = text.trim();
    if (agent == null || trimmed.isEmpty || sending) return;
    if (token == null || token!.isEmpty) {
      chatError = '未登录';
      notifyListeners();
      return;
    }
    sending = true;
    chatError = null;
    lastUserText = trimmed;
    if (!retry) {
      messages = [
        ...messages,
        ChatMessage(
          id: 'local-user-${DateTime.now().microsecondsSinceEpoch}',
          role: MessageRole.user,
          content: trimmed,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: 'local-assistant',
          role: MessageRole.assistant,
          content: '',
          timestamp: DateTime.now(),
          isStreaming: true,
        ),
      ];
    } else {
      messages = [
        for (final message in messages)
          if (message.id == 'local-assistant')
            message.copyWith(content: '', isStreaming: true, error: null)
          else
            message,
      ];
    }
    notifyListeners();

    final uri = chatWebSocketUri(baseUrl, agent.agentId, token!);
    try {
      await _socket?.close();
      final link = _connect(uri);
      _socket = link;
      var state = ChatTurnState(threadId: activeThreadId);
      link.send(
        userTurnPayload(text: trimmed, threadId: activeThreadId),
      );
      await for (final frame in link.frames) {
        state = state.apply(frame);
        _replaceAssistant(state.assistantText, streaming: !state.done);
        if (state.threadId != null && state.threadId != activeThreadId) {
          activeThreadId = state.threadId;
        }
        if (state.error != null) {
          chatError = state.error;
        }
        notifyListeners();
        if (state.done || state.error != null) break;
      }
      if (chatError == null && state.assistantText.isEmpty && !state.done) {
        chatError = '没有收到回复';
      }
    } on ApiException catch (error) {
      chatError = error.message;
    } catch (_) {
      chatError = '服务不可达';
    } finally {
      sending = false;
      _replaceAssistant(
        messages.isEmpty ? '' : _assistantText(),
        streaming: false,
      );
      await _socket?.close();
      _socket = null;
      notifyListeners();
    }
    if (chatError == null) {
      await refreshThreads();
    }
  }

  Future<void> _loadAgents() async {
    agents = await _client.listAgents();
    selectedAgent = pickDefaultAgent(agents);
    if (selectedAgent == null) {
      banner = '未找到可用 Agent';
      return;
    }
    threads = await _client.listThreads(selectedAgent!.agentId);
    ThreadSummary? initial;
    for (final thread in threads) {
      if (thread.isActive) {
        initial = thread;
        break;
      }
    }
    initial ??= threads.isEmpty ? null : threads.first;
    if (initial != null) {
      activeThreadId = initial.threadId;
      messages = await _client.history(
        selectedAgent!.agentId,
        initial.threadId,
      );
    }
  }

  Future<void> _clearSession() async {
    token = null;
    user = null;
    _client.token = null;
    await _store.delete(_tokenKey);
  }

  void _applySpace(ProjectSpace space) {
    projects = space.projects;
    projectsCollapsed = space.collapsed;
    activeProjectId = space.activeId;
    notifyListeners();
  }

  void _replaceAssistant(String text, {required bool streaming}) {
    var found = false;
    messages = [
      for (final message in messages)
        if (message.id == 'local-assistant')
          () {
            found = true;
            return message.copyWith(content: text, isStreaming: streaming);
          }()
        else
          message,
    ];
    if (!found && (text.isNotEmpty || streaming)) {
      messages = [
        ...messages,
        ChatMessage(
          id: 'local-assistant',
          role: MessageRole.assistant,
          content: text,
          timestamp: DateTime.now(),
          isStreaming: streaming,
        ),
      ];
    }
  }

  String _assistantText() {
    for (final message in messages) {
      if (message.id == 'local-assistant') return message.content;
    }
    return '';
  }

  @override
  void dispose() {
    _socket?.close();
    super.dispose();
  }
}
