import EventKit
import Foundation

final class CalendarMonitor {
    private let eventStore = EKEventStore()
    private(set) var accessGranted = false

    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.accessGranted = granted
                    completion(granted)
                }
            }
        }
    }

    /// Check if there's a busy event at the given date for the specified calendar
    func hasBusyEvent(at date: Date, calendarIdentifier: String) -> Bool {
        guard accessGranted else { return false }

        let calendar: EKCalendar?
        if calendarIdentifier.isEmpty {
            calendar = eventStore.defaultCalendarForNewEvents
        } else {
            calendar = eventStore.calendars(for: .event).first { $0.calendarIdentifier == calendarIdentifier }
        }

        guard let cal = calendar else { return false }

        // Check events in a 1-minute window around the date
        let start = date.addingTimeInterval(-30)
        let end = date.addingTimeInterval(30)
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: [cal])
        let events = eventStore.events(matching: predicate)

        return events.contains { event in
            event.availability == .busy || event.availability == .unavailable
        }
    }

    /// Get all available calendars
    var availableCalendars: [(id: String, title: String)] {
        guard accessGranted else { return [] }
        return eventStore.calendars(for: .event).map { ($0.calendarIdentifier, $0.title) }
    }
}
