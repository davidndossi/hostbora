import 'dart:async';

import 'package:get/get.dart';
import 'package:local_session_timeout/local_session_timeout.dart';

class SessionService extends GetxService {
  late StreamController<SessionState> sessionStateStream;

  StreamController<SessionState> init() {
    sessionStateStream = StreamController<SessionState>();

    return sessionStateStream;
  }
}