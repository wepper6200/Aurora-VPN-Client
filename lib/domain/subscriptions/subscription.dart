/// Traffic quota and expiry from the `subscription-userinfo` header.
class SubscriptionUsage {
  const SubscriptionUsage({this.upload = 0, this.download = 0, this.total = 0, this.expire});

  final int upload;
  final int download;

  /// 0 means unlimited.
  final int total;
  final DateTime? expire;

  int get used => upload + download;
  bool get unlimited => total <= 0;

  /// 0..1, or `null` when unlimited.
  double? get usedFraction => unlimited ? null : (used / total).clamp(0, 1).toDouble();

  int? get remaining => unlimited ? null : (total - used).clamp(0, total);
}

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.updatedAt,
    this.updateInterval = const Duration(hours: 12),
    this.autoUpdate = true,
    this.usage,
    this.supportUrl,
  });

  final String id;
  final String name;
  final String url;
  final DateTime? updatedAt;

  /// From `profile-update-interval` (hours) or set by the user.
  final Duration updateInterval;
  final bool autoUpdate;
  final SubscriptionUsage? usage;
  final String? supportUrl;
}
