import Foundation
import UserNotifications

/// All local-notification scheduling for retention. Every scheduler is
/// idempotent (removes its own family by identifier before re-adding), so
/// calling `syncAll` repeatedly never stacks duplicates.
@MainActor
final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    @Published var authStatus: UNAuthorizationStatus = .notDetermined

    enum ID {
        static let dailyReminder = "calm.daily"
        static let streakRisk    = "calm.streakRisk"
        static let taskReminder  = "calm.task"
        static let trialEnding   = "calm.trialEnding"
        static let winBack       = "calm.winBack"
    }

    func bootstrap() {
        center.delegate = self
        Task { await refreshAuthStatus() }
    }

    func refreshAuthStatus() async {
        authStatus = await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthStatus()
        return granted
    }

    /// True if the user already logged something today (exact, from lastActiveDate).
    func hasActivityToday(_ profile: UserProfile) -> Bool {
        guard let last = profile.lastActiveDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    // MARK: - Orchestration

    func syncAll(profile: UserProfile, hasActivityToday: Bool) async {
        await refreshAuthStatus()
        guard profile.notificationsEnabled, authStatus == .authorized else {
            cancelAll(); return
        }
        await scheduleDailyReminder(at: profile.reminderTime)
        await scheduleStreakRisk(hasActivityToday: hasActivityToday,
                                 reminderTime: profile.reminderTime,
                                 currentStreak: profile.currentStreak)
        await scheduleWinBack(reminderTime: profile.reminderTime, calmName: profile.calmName)
    }

    /// Lapsed-user win-back: fires 3 days from now at the reminder hour, and is
    /// re-armed on every sync — so it only ever fires if the user truly stops
    /// opening the app. The highest-ROI notification in any habit product.
    func scheduleWinBack(reminderTime: Date, calmName: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.winBack])
        let cal = Calendar.current
        guard let base = cal.date(byAdding: .day, value: 3, to: Date()) else { return }
        let h = cal.component(.hour, from: reminderTime), m = cal.component(.minute, from: reminderTime)
        guard let fire = cal.date(bySettingHour: h, minute: m, second: 0, of: base) else { return }
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let name = calmName.isEmpty ? "there" : calmName
        let content = makeContent(String(localized: "We're still here, \(name)"),
                                  String(localized: "Anxiety doesn't wait — and neither does your anchor. One breath is enough to come back."))
        try? await center.add(UNNotificationRequest(identifier: ID.winBack, content: content, trigger: trigger))
    }

    /// Cancels the reminder family only. Deliberately spares the trial-ending
    /// notice: turning off daily reminders must not silently drop the
    /// "your trial converts tomorrow" heads-up we promised at purchase.
    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [
            ID.dailyReminder, ID.streakRisk, ID.taskReminder, ID.winBack
        ])
    }

    /// Full wipe — used by "Reset All Data" (which also drops the entitlement context).
    func cancelEverything() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelStreakRisk() {
        center.removePendingNotificationRequests(withIdentifiers: [ID.streakRisk])
    }

    // MARK: - Schedulers

    func scheduleDailyReminder(at time: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.dailyReminder])
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let content = makeContent(String(localized: "Your daily anchor 🌊"),
                                  String(localized: "A few minutes of calm is waiting. Check in with yourself."))
        try? await center.add(UNNotificationRequest(identifier: ID.dailyReminder,
                                                    content: content, trigger: trigger))
    }

    /// One-shot for tonight only; recomputed on background and cancelled the
    /// moment the user logs activity. Skips if nothing's at stake or window passed.
    func scheduleStreakRisk(hasActivityToday: Bool, reminderTime: Date, currentStreak: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.streakRisk])
        guard !hasActivityToday, currentStreak >= 1 else { return }

        let cal = Calendar.current
        guard var fire = cal.date(bySettingHour: 20, minute: 30, second: 0, of: Date()) else { return }
        // keep streak-risk at least 30 min after the daily reminder
        if let rt = cal.date(bySettingHour: cal.component(.hour, from: reminderTime),
                             minute: cal.component(.minute, from: reminderTime),
                             second: 0, of: Date()),
           rt.addingTimeInterval(1800) > fire {
            fire = rt.addingTimeInterval(1800)
        }
        // Never let the nudge spill past midnight — that would arrive after the
        // streak has already lapsed. Clamp to 23:45 today at the latest.
        if let latest = cal.date(bySettingHour: 23, minute: 45, second: 0, of: Date()), fire > latest {
            fire = latest
        }
        guard fire > Date() else { return }

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let content = makeContent(String(localized: "Keep your \(currentStreak)-day streak alive 🔥"),
                                  String(localized: "A quick mood log or journal entry keeps your momentum going."))
        try? await center.add(UNNotificationRequest(identifier: ID.streakRisk,
                                                    content: content, trigger: trigger))
    }

    func scheduleTrialEnding(trialEnds: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [ID.trialEnding])
        await refreshAuthStatus()
        let remindAt = trialEnds.addingTimeInterval(-24 * 3600)
        guard authStatus == .authorized, remindAt > Date() else { return }
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let content = makeContent(String(localized: "Your free trial ends tomorrow"),
                                  String(localized: "Your CalmAnchor Pro trial converts in 24 hours. Manage anytime in Settings."))
        try? await center.add(UNNotificationRequest(identifier: ID.trialEnding,
                                                    content: content, trigger: trigger))
    }

    func cancelTrialEnding() {
        center.removePendingNotificationRequests(withIdentifiers: [ID.trialEnding])
    }

    // MARK: - Helpers

    private func makeContent(_ title: String, _ body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
