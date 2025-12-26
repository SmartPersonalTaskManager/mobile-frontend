import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationService {
  static const String key = "notifications";

  Future<List<NotificationItem>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) return sampleNotifications();

    final List decoded = json.decode(jsonStr);
    return decoded.map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<void> saveNotifications(List<NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((e) => e.toJson()).toList();
    await prefs.setString(key, json.encode(list));
  }

  Future<void> markAllRead() async {
    final items = await loadNotifications();
    for (var n in items) {
      n.read = true;
    }
    await saveNotifications(items);
  }

  Future<void> markRead(String id) async {
    final items = await loadNotifications();
    for (var n in items) {
      if (n.id == id) n.read = true;
    }
    await saveNotifications(items);
  }

  List<NotificationItem> sampleNotifications() {
    return [
      NotificationItem(
        id: "1",
        title: "Due Today: Complete draft for Project Proposal",
        message: "The initial draft is due by 5 PM. Don’t forget to include the budget section.",
        time: "2m ago",
        read: false,
      ),
      NotificationItem(
        id: "2",
        title: "Quarterly Mission Statement Review",
        message: "Your scheduled review starts in 10 minutes.",
        time: "1h ago",
        read: false,
      ),
      NotificationItem(
        id: "3",
        title: "Alignment Tip",
        message: "You recently linked a task to your 'Health' mission. Try adding a workout.",
        time: "Yesterday",
        read: true,
      ),
    ];
  }
}
