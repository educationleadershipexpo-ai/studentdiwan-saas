// FCM stub for the unified app.
//
// The standalone parent-app depended on `firebase_messaging`; the unified
// student-app does not bundle Firebase, so this is a no-op shim that preserves
// the FcmService API surface the parent settings screen calls (onLogout/init).
// Push notifications are handled at the host-app level if/when enabled.
class FcmService {
  static Future<void> init() async {}

  static Future<void> onLogout() async {}
}
