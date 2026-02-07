import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ---- Auth events ----

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // ---- Post events ----

  Future<void> logPostCreated({
    required String type,
    required bool isGlobal,
    required double radius,
  }) async {
    await _analytics.logEvent(
      name: 'post_created',
      parameters: {
        'type': type,
        'is_global': isGlobal,
        'radius_km': radius,
      },
    );
  }

  Future<void> logPostAccepted() async {
    await _analytics.logEvent(name: 'post_accepted');
  }

  // ---- Chat events ----

  Future<void> logMessageSent() async {
    await _analytics.logEvent(name: 'message_sent');
  }

  // ---- Task events ----

  Future<void> logTaskCompleted() async {
    await _analytics.logEvent(name: 'task_completed');
  }

  // ---- Badge events ----

  Future<void> logBadgeEarned({required String badgeId}) async {
    await _analytics.logEvent(
      name: 'badge_earned',
      parameters: {'badge_id': badgeId},
    );
  }

  // ---- User properties ----

  Future<void> setUserProperties({
    required String userId,
    int? trustScore,
  }) async {
    await _analytics.setUserId(id: userId);
    if (trustScore != null) {
      await _analytics.setUserProperty(
        name: 'trust_score',
        value: trustScore.toString(),
      );
    }
  }

  // ---- Non-fatal error logging (via Crashlytics) ----

  Future<void> logNonFatalError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason ?? 'non-fatal',
    );
  }
}
