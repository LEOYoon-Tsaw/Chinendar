//
//  ReminderSpotlight.swift
//  Chinendar
//
//  Created by Leo Liu on 10/14/26.
//

import CoreSpotlight
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// A complete snapshot lets us remove deleted reminders as well as update existing ones.
@MainActor
final class ReminderSpotlight {
    nonisolated static let domain = "Chinendar.Reminders"

    struct Entry: Equatable, Sendable {
        let id: UUID
        let title: String
        let date: Date?
        let enabled: Bool

        var searchableItem: CSSearchableItem {
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = title
            attributes.contentDescription = enabled ? String(localized: "REMINDER_ENABLED") : String(localized: "REMINDER_DISABLED")
            attributes.startDate = date
            let item = CSSearchableItem(uniqueIdentifier: ReminderSpotlight.identifier(for: id),
                                        domainIdentifier: ReminderSpotlight.domain, attributeSet: attributes)
            item.expirationDate = date
            return item
        }
    }

    private struct Snapshot: Sendable {
        let lists: [ReminderList]
        let calendar: ChineseCalendar
    }

    private var indexedEntries: [Entry]?
    private var pendingSnapshot: Snapshot?
    private var indexingTask: Task<Void, Never>?

    nonisolated static func identifier(for id: UUID) -> String {
        "\(domain).\(id.uuidString)"
    }

    static func reminderID(from activity: NSUserActivity) -> UUID? {
        guard activity.activityType == CSSearchableItemActionType,
              let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              identifier.hasPrefix(domain + ".") else { return nil }
        return UUID(uuidString: String(identifier.dropFirst(domain.count + 1)))
    }

    @concurrent
    private static func entries(for snapshot: Snapshot) async -> [Entry]? {
        guard !Task.isCancelled else { return nil }
        // Settings can preview another date; search always describes the next real occurrence.
        var calendar = snapshot.calendar
        calendar.update(time: .now)
        var seen = Set<UUID>()
        var entries: [Entry] = []
        for list in snapshot.lists {
            for reminder in list.reminders {
                guard !Task.isCancelled else { return nil }
                guard seen.insert(reminder.id).inserted else { continue }
                entries.append(Entry(id: reminder.id, title: reminder.name, date: reminder.nextEvent(in: calendar),
                                     enabled: list.enabled && reminder.enabled))
            }
        }
        return entries.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    func update(lists: [ReminderList], calendar: ChineseCalendar) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        pendingSnapshot = Snapshot(lists: lists, calendar: calendar)
        guard indexingTask == nil else { return }
        indexingTask = Task {
            await indexPendingEntries()
        }
    }

    private func indexPendingEntries() async {
        // Coalesce inputs before calculating, then serialize writes so older snapshots cannot win.
        while pendingSnapshot != nil {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let snapshot = pendingSnapshot else { break }
            pendingSnapshot = nil
            guard let entries = await Self.entries(for: snapshot) else { break }
            // An edit arrived during calculation; calculate its fresh snapshot before indexing.
            guard pendingSnapshot == nil else { continue }
            guard entries != indexedEntries else { continue }
            let index = CSSearchableIndex.default()
            do {
                if let indexedEntries {
                    let currentIDs = Set(entries.map(\.id))
                    let removedIDs = indexedEntries.filter { !currentIDs.contains($0.id) }.map { Self.identifier(for: $0.id) }
                    if !removedIDs.isEmpty {
                        try await index.deleteSearchableItems(withIdentifiers: removedIDs)
                    }
                } else {
                    // Reconcile with items left by previous launches, including deletions while the app was closed.
                    try await index.deleteSearchableItems(withDomainIdentifiers: [Self.domain])
                }
                if !entries.isEmpty {
                    try await index.indexSearchableItems(entries.map(\.searchableItem))
                }
                indexedEntries = entries
            } catch {
                indexedEntries = nil
                print("Reminder Spotlight indexing failed: \(error.localizedDescription)")
            }
        }
        indexingTask = nil
    }
}

/// Register every reminder destination at the stack root, including when opening a full Spotlight path.
enum ReminderDestination: Hashable {
    case group(RemindersData)
    case reminder(RemindersData, UUID)
}

extension View {
    func reminderDestinations() -> some View {
        navigationDestination(for: ReminderDestination.self) { destination in
            switch destination {
            case .group(let group):
                ReminderGroup(remindersData: group)
            case .reminder(let group, let id):
                ReminderConfig(remindersData: group, reminderID: id)
            }
        }
    }

    func reminderSpotlight(isSettings: Bool = false) -> some View {
        modifier(ReminderSpotlightObserver(isSettings: isSettings))
    }
}

private struct ReminderSpotlightObserver: ViewModifier {
    let isSettings: Bool
    @Query(filter: RemindersData.predicate, sort: [SortDescriptor(\RemindersData.modifiedDate, order: .reverse)]) private var groups: [RemindersData]
    @Environment(ViewModel.self) private var viewModel
#if os(macOS) || os(visionOS)
    @Environment(\.openWindow) private var openWindow
#endif

    func body(content: Content) -> some View {
        content
            .onChange(of: groups.compactMap(\.instance), initial: true) { _, lists in
                viewModel.reminderSpotlight.update(lists: lists, calendar: viewModel.chineseCalendar)
            }
            .onChange(of: viewModel.chineseCalendar) {
                viewModel.reminderSpotlight.update(lists: groups.compactMap(\.instance), calendar: viewModel.chineseCalendar)
            }
#if os(macOS) || os(visionOS)
            .handlesExternalEvents(preferring: isSettings ? ["*"] : [], allowing: ["*"])
#endif
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                guard let id = ReminderSpotlight.reminderID(from: activity), viewModel.openReminder(id: id) else { return }
#if os(macOS) || os(visionOS)
                if !isSettings {
                    openWindow(id: "Settings")
                }
#endif
#if os(macOS)
                NSApp.activate()
#endif
            }
    }
}

extension ViewModel {
    func updateReminderSpotlight() {
        do {
            let lists = try RemindersData.load(context: DataSchema.container.mainContext)
            reminderSpotlight.update(lists: lists, calendar: chineseCalendar)
        } catch {
            print("Loading reminders for Spotlight failed: \(error.localizedDescription)")
        }
    }

    @discardableResult
    func openReminder(id: UUID) -> Bool {
        do {
            let descriptor = FetchDescriptor(predicate: RemindersData.predicate, sortBy: [SortDescriptor(\.modifiedDate, order: .reverse)])
            let groups = try DataSchema.container.mainContext.fetch(descriptor)
            guard let group = groups.first(where: { $0.instance?.reminders.contains(where: { $0.id == id }) == true }) else {
                updateReminderSpotlight()
                return false
            }
            var path = NavigationPath()
#if os(iOS)
            path.append(WatchSetting.Selection.reminders)
            settings.presentSetting = true
#elseif os(macOS)
            settings.selection = .reminders
            settings.previousSelection = .reminders
#elseif os(visionOS)
            settings.tabSelection = .spaceTime
            settings.selectionSpaceTime = .reminders
#endif
            path.append(ReminderDestination.group(group))
            path.append(ReminderDestination.reminder(group, id))
            settings.path = path
            return true
        } catch {
            self.error = error
            return false
        }
    }
}
