import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class PartyPairingClient {
  PartyPairingClient();

  bool _isInitialized = false;

  Future<ServiceRequestResult> startService() async {
    await _initializeForegroundTask();

    bool isRunningService = await FlutterForegroundTask.isRunningService;
    if (isRunningService) {
      return ServiceRequestResult.success;
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
      return ServiceRequestResult.success;
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
      foregroundTaskOptions: const ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
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
  FlutterForegroundTask.setTaskHandler(_PartyPairingTaskHandler());
}

class _PartyPairingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}
}
