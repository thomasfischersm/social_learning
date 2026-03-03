import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:social_learning/session_pairing/party_pairing_service/party_pairing_foreground_task.dart';

class PartyPairingClient {
  PartyPairingClient();

  bool _isInitialized = false;

  Future<ServiceRequestResult> startService() async {
    await _initializeForegroundTask();

    bool isRunningService = await FlutterForegroundTask.isRunningService;
    if (isRunningService) {
      return ServiceRequestSuccess();
    }

    return FlutterForegroundTask.startService(
      serviceId: 42601,
      notificationTitle: 'Party pairing is active',
      notificationText: 'Matching peers in the background.',
      callback: _startPartyPairingIsolate,
    );
  }

  Future<ServiceRequestResult> stopService() async {
    bool isRunningService = await FlutterForegroundTask.isRunningService;
    if (!isRunningService) {
      return ServiceRequestSuccess();
    }

    return FlutterForegroundTask.stopService();
  }

  Future<void> _initializeForegroundTask() async {
    if (_isInitialized) {
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'party_pairing_service_channel',
        channelName: 'Party Pairing Service',
        channelDescription: 'Runs party pairing in a foreground isolate.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.once(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
  }
}

@pragma('vm:entry-point')
void _startPartyPairingIsolate() {
  FlutterForegroundTask.setTaskHandler(PartyPairingForegroundTask());
}
