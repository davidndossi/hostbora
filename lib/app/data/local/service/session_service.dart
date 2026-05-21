import 'dart:async';

import 'package:get/get.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

/// Placeholder for [local_session_timeout] integration.
///
/// Idle session timeout is not wired into the app lifecycle yet. When adding it,
/// register this service in bindings and connect [sessionStateStream] to logout
/// or the welcome-back lock flow.
class SessionService extends GetxService {
  late StreamController<SessionState> sessionStateStream;

  StreamController<SessionState> init() {
    sessionStateStream = StreamController<SessionState>();

    return sessionStateStream;
  }
}
