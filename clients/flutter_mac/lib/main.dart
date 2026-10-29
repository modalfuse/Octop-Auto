import 'package:flutter/material.dart';

import 'app.dart';
import 'services/credential_store.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(OctopApp(state: AppState(store: SecureCredentialStore())));
}
