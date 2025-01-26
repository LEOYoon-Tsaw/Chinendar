//
//  Notification.swift
//  Chinendar
//
//  Created by Leo Liu on 1/5/25.
//

@preconcurrency import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()

    let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws -> Bool {
        return try await center.requestAuthorization(options: [.alert, .sound])
    }

    var enabled: Bool {
        get async {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .denied, .notDetermined:
                return false
            case .authorized, .provisional, .ephemeral:
                return true
            @unknown default:
                return false
            }
        }
    }

    func addNotifications(chineseCalendar: ChineseCalendar) async throws {
        guard await enabled else { return }
        let modelContext = DataModel.shared.modelExecutor.modelContext
        let remindersList = try RemindersData.load(context: modelContext)

        var reminders: [Reminder] = []
        for list in remindersList where list.enabled {
            for reminder in list.reminders where reminder.enabled {
                reminders.append(reminder)
            }
        }
        var notifications = await withTaskGroup(of: Optional<(Date, UNNotificationRequest)>.self) { group in
            for reminder in reminders {
                guard !group.isCancelled else { break }
                group.addTask {
                    if let eventTime = reminder.nextEvent(in: chineseCalendar), let triggerTime = reminder.nextReminder(in: chineseCalendar) {
                        let formatter = RelativeDateTimeFormatter()
                        formatter.dateTimeStyle = .named
                        let timeLeft = formatter.localizedString(for: eventTime, relativeTo: triggerTime)

                        let notification = UNMutableNotificationContent()
                        notification.title = reminder.name
                        if eventTime > .now {
                            notification.body = String(localized: "EVENT\(reminder.name)HAPPEN_IN\(timeLeft)")
                        } else {
                            notification.body = String(localized: "EVENT\(reminder.name)HAPPENED_ON\(timeLeft)")
                        }
                        notification.sound = .default
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime.timeIntervalSinceNow, repeats: false)
                        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: notification, trigger: trigger)
                        return (time: triggerTime, request: request)
                    } else {
                        return nil
                    }
                }
            }

            var notifications: [(time: Date, request: UNNotificationRequest)] = []
            for await result in group {
                if let result {
                    notifications.append(result)
                }
            }
            return notifications
        }

        notifications.sort { $0.time < $1.time }
        var count = 0
        for notification in notifications {
            guard count < 64 else { break }
            do {
                try await center.add(notification.request)
                count += 1
            } catch {
                print("Error when adding notification: \(error)")
                continue
            }
        }
    }

    func clearNotifications() {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    private init() {}
}
