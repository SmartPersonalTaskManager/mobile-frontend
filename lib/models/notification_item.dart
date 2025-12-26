class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "message": message,
    "time": time,
    "read": read,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json["id"],
      title: json["title"],
      message: json["message"],
      time: json["time"],
      read: json["read"],
    );
  }
}