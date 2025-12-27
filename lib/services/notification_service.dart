import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationService {
  static const String key = "notifications";
  static const String _weeklyInsightsKey = "weekly_insights_last_sent";

  Future<List<NotificationItem>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);

    final items =
        jsonStr == null
            ? <NotificationItem>[]
            : (json.decode(jsonStr) as List)
                .map((e) => NotificationItem.fromJson(e))
                .toList();
    await _maybeAddWeeklyInsights(prefs, items);
    return items;
  }

  Future<void> _maybeAddWeeklyInsights(
    SharedPreferences prefs,
    List<NotificationItem> items,
  ) async {
    final now = DateTime.now();
    final sunday = _startOfWeekSunday(now);
    final scheduled = DateTime(sunday.year, sunday.month, sunday.day, 8);
    if (now.isBefore(scheduled)) {
      return;
    }

    final weekKey = _formatDateKey(sunday);
    final lastSentKey = prefs.getString(_weeklyInsightsKey);
    final notificationId = "weekly_insights_$weekKey";
    final alreadyAdded = items.any((item) => item.id == notificationId);
    if (lastSentKey == weekKey || alreadyAdded) {
      return;
    }

    items.insert(
      0,
      NotificationItem(
        id: notificationId,
        title: "Weekly Insights Ready",
        message: "Review your weekly insights and plan the week ahead.",
        time: "Sunday 8:00 AM",
        read: false,
      ),
    );
    await prefs.setString(_weeklyInsightsKey, weekKey);
    await saveNotifications(items);
  }

  DateTime _startOfWeekSunday(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final daysSinceSunday = normalized.weekday % 7;
    return normalized.subtract(Duration(days: daysSinceSunday));
  }

  String _formatDateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "${date.year}-$month-$day";
  }

  Future<void> saveNotifications(List<NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((e) => e.toJson()).toList();
    await prefs.setString(key, json.encode(list));
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);

    final now = DateTime.now();
    final sunday = _startOfWeekSunday(now);
    final scheduled = DateTime(sunday.year, sunday.month, sunday.day, 8);
    if (!now.isBefore(scheduled)) {
      await prefs.setString(_weeklyInsightsKey, _formatDateKey(sunday));
    }
  }

  Future<void> markRead(String id) async {
    final items = await loadNotifications();
    items.removeWhere((n) => n.id == id);
    await saveNotifications(items);
  }
}
