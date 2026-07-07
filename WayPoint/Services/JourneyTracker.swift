//
//  JourneyTracker.swift
//  WayPoint
//
//  Created on 07/07/2026.
//

import Foundation
import Observation
import UserNotifications

/// Phase 4: monitors one tracked service, refreshing it from the live
/// service detail endpoint and raising permission-gated local notifications
/// for cancellation, platform changes, and new delays.
@Observable
final class JourneyTracker {
    private enum StorageKey {
        static let journey = "waypoint.trackedJourney"
    }

    private enum NotificationID {
        static let departureReminder = "waypoint.journey.departureReminder"
        static let statusChange = "waypoint.journey.statusChange"
    }

    private(set) var journey: TrackedJourney?
    private(set) var isRefreshing = false
    private(set) var notificationsDenied = false

    private let defaults: UserDefaults
    private let service = DepartureService.shared
    private let presenter = ForegroundNotificationPresenter()
    private var pollTask: Task<Void, Never>?

    /// How often the tracked service is re-fetched while the app is running.
    private let pollInterval: TimeInterval = 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        UNUserNotificationCenter.current().delegate = presenter

        if let data = defaults.data(forKey: StorageKey.journey),
           let stored = try? JSONDecoder().decode(TrackedJourney.self, from: data) {
            if stored.isExpired() {
                defaults.removeObject(forKey: StorageKey.journey)
            } else {
                journey = stored
                // Re-request if the user never answered the prompt before quitting.
                Task { await requestNotificationPermission() }
                startPolling()
            }
        }
    }

    var isTracking: Bool { journey != nil }

    func isTracking(serviceId: String?) -> Bool {
        guard let serviceId else { return false }
        return journey?.serviceId == serviceId
    }

    // MARK: - Start / stop

    func track(_ trip: RailTrip) {
        guard let serviceId = trip.serviceId else { return }

        let newJourney = TrackedJourney(trip: trip, serviceId: serviceId)
        journey = newJourney
        persist()

        Task {
            await requestNotificationPermission()
            scheduleDepartureReminder(for: newJourney)
        }
        startPolling()
    }

    func stopTracking() {
        pollTask?.cancel()
        pollTask = nil
        journey = nil
        defaults.removeObject(forKey: StorageKey.journey)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.departureReminder])
    }

    // MARK: - Refresh

    func refresh() async {
        guard var current = journey, !isRefreshing else { return }

        if current.isExpired() {
            stopTracking()
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let detail = try await service.fetchServiceDetail(serviceId: current.serviceId)
            apply(detail: detail, to: &current)
            current.lastUpdatedAt = .now
            current.lastUpdateFailed = false
        } catch {
            current.lastUpdateFailed = true
        }

        // Tracking may have stopped (or switched trains) while the fetch was
        // in flight — never resurrect a journey the user dismissed.
        guard journey?.serviceId == current.serviceId else { return }
        journey = current
        persist()
    }

    private func apply(detail: Huxley2ServiceDetail, to current: inout TrackedJourney) {
        let newStatus = HuxleyStatus.statusText(std: detail.std, etd: detail.etd, isCancelled: detail.isCancelled)
        let newPlatform = detail.platform
        let newCancelled = detail.isCancelled ?? false
        let newReason = detail.cancelReason ?? detail.delayReason

        if newCancelled && !current.notifiedCancellation {
            current.notifiedCancellation = true
            var body = "Your \(current.scheduledDeparture) to \(current.destinationName) has been cancelled."
            if let reason = detail.cancelReason { body += " \(reason)" }
            sendNotification(title: "Train cancelled", body: body)
        }

        if !newCancelled, let platform = newPlatform, platform != current.notifiedPlatform {
            // Only alert when the platform actually changed or was first announced.
            let title = current.notifiedPlatform == nil ? "Platform announced" : "Platform changed"
            current.notifiedPlatform = platform
            sendNotification(
                title: title,
                body: "Your \(current.scheduledDeparture) to \(current.destinationName) departs from platform \(platform)."
            )
        }

        let delay = HuxleyStatus.delayMinutes(std: detail.std, etd: detail.etd) ?? 0
        let isNewDelay = !newCancelled
            && (newStatus == "Delayed" || delay >= 5)
            && newStatus != current.notifiedDelayedStatus
        if isNewDelay {
            current.notifiedDelayedStatus = newStatus
            var body = newStatus == "Delayed"
                ? "Your \(current.scheduledDeparture) to \(current.destinationName) is delayed."
                : "Your \(current.scheduledDeparture) to \(current.destinationName) is running \(delay) min late (\(newStatus))."
            if let reason = detail.delayReason { body += " \(reason)" }
            sendNotification(title: "Train delayed", body: body)
        }

        current.status = newStatus
        current.platform = newPlatform ?? current.platform
        current.isCancelled = newCancelled
        current.disruptionReason = newReason
    }

    // MARK: - Polling

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.pollInterval ?? 60))
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            notificationsDenied = !granted
        case .denied:
            notificationsDenied = true
        default:
            notificationsDenied = false
        }
    }

    /// A one-shot heads-up shortly before the scheduled departure.
    private func scheduleDepartureReminder(for journey: TrackedJourney) {
        guard let departure = journey.departureDate else { return }
        let fireDate = departure.addingTimeInterval(-10 * 60)
        let interval = fireDate.timeIntervalSinceNow
        guard interval > 5 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Departure soon"
        var body = "Your \(journey.scheduledDeparture) to \(journey.destinationName) leaves in 10 minutes"
        if let platform = journey.platform { body += " from platform \(platform)" }
        content.body = body + "."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.departureReminder,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(NotificationID.statusChange).\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func persist() {
        guard let journey, let data = try? JSONEncoder().encode(journey) else {
            defaults.removeObject(forKey: StorageKey.journey)
            return
        }
        defaults.set(data, forKey: StorageKey.journey)
    }
}

/// Shows tracked-journey notifications as banners even while the app is frontmost.
private final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
