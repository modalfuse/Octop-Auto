import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octop_auto_flutter/app.dart';
import 'package:octop_auto_flutter/config/defaults.dart';
import 'package:octop_auto_flutter/services/api_client.dart';
import 'package:octop_auto_flutter/services/credential_store.dart';
import 'package:octop_auto_flutter/state/app_state.dart';

void main() {
  testWidgets('first launch confirms the default hp02 base url',
      (tester) async {
    final state = AppState(
      store: MemoryCredentialStore(),
      transport: _IdleTransport(),
    );
    await state.load();

    await tester.pumpWidget(OctopApp(state: state));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, kDefaultBaseUrl);
    expect(find.text('探测'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump();

    expect(state.baseUrlConfirmed, isTrue);
    expect(state.baseUrl, kDefaultBaseUrl);
    expect(find.text('登录'), findsWidgets);
  });
}

class _IdleTransport implements HttpTransport {
  @override
  Future<ApiResponse> send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    String? body,
  }) async {
    return const ApiResponse(200, '{"status":"ok"}');
  }
}
