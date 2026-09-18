import 'dart:async';

import 'package:kac_gun_oldu/domain/reminders.dart';
import 'package:kac_gun_oldu/services/reminders.dart';

/// Records what the app asks the operating system to do.
class FakeReminders implements Reminders {
  FakeReminders({this.granted = true, this.launchedWith});

  bool granted;
  final String? launchedWith;
  final tapController = StreamController<String>.broadcast();

  int permissionAsks = 0;
  int syncs = 0;
  List<Reminder> plan = const [];
  final shown = <(String, String)>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return granted;
  }

  @override
  Future<void> sync(List<Reminder> plan) async {
    syncs++;
    this.plan = plan;
  }

  @override
  Future<void> showNow(String title, String body) async => shown.add((title, body));

  @override
  Future<String?> launchCardId() async => launchedWith;

  @override
  Stream<String> get taps => tapController.stream;
}
