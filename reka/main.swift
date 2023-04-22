import EventKit
import Foundation

private let Store = EKEventStore()


public final class Calendars2 {
    private static func requestAccess(for type: EKEntityType) -> Bool{
        let semaphore = DispatchSemaphore(value: 0)
        var grantedAccess = false
        Store.requestAccess(to: type) { granted, _ in
            grantedAccess = granted
            semaphore.signal()
        }
        semaphore.wait()
        
        return grantedAccess
    }
    
    
    public static func requestAccess() -> Bool {
        return requestAccess(for: .reminder) && requestAccess(for: .event)
    }
    
    func showLists(for type: EKEntityType) {
        let calendars = self.getCalendars(for: type)
        for calendar in calendars {
            print(calendar.title)
        }
    }
    
    func showCalendarLists() {
        showLists(for: .event)
    }
    
    func showRemindersLists() {
        showLists(for: .reminder)
    }
    
    func showListItems(withName name: String) {
        let calendar = self.calendar(withName: name)
        let semaphore = DispatchSemaphore(value: 0)
        
        self.reminders(onCalendar: calendar) { reminders in
            for (_, reminder) in reminders.enumerated() {
                print(reminder)
                //                                print(format(reminder, at: i))
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
    }
    
    func addEvent(){
        let calendar = self.calendar(withName: "Home")
        let ev = EKEvent(eventStore: Store)
        ev.calendar = calendar
        ev.title = "Some Test event"
        ev.isAllDay = false
        
        
        ev.startDate = Date.now
        
        let dayComp = DateComponents(minute: 30)
        let date = Calendar.current.date(byAdding: dayComp, to: Date()) ?? Date.now
        
        ev.endDate = date
        
        do {
            try Store.save(ev, span: .thisEvent, commit: true)
            print("Added '\(ev.title!)' to '\(calendar.title)'")
        } catch let error {
            print("Failed to save reminder with error: \(error)")
            exit(1)
        }
    }
    
    
    // MARK: - Private functions
    
    private func reminders(onCalendar calendar: EKCalendar,
                           completion: @escaping (_ reminders: [EKReminder]) -> Void)
    {
        let dayComp = DateComponents(day: -6)
        let date = Calendar.current.date(byAdding: dayComp, to: Date()) ?? Date.now
        
        let predicate = Store.predicateForEvents(withStart: date, end: Date.now, calendars: [calendar])
        
        for ev in Store.events(matching: predicate){
            print(ev)
        }
        
    }
    
    private func calendar(for type: EKEntityType, withName name: String) -> EKCalendar {
        if let calendar = self.getCalendars(for: type).first(where: { $0.title.lowercased() == name.lowercased() }) {
            return calendar
        } else {
            print("No reminders list matching \(name)")
            exit(1)
        }
    }
    
    private func getCalendars(for type: EKEntityType) -> [EKCalendar] {
        return Store.calendars(for: type)
            .filter { $0.allowsContentModifications }
    }
}


if Calendars2.requestAccess() {
    let reminders = Calendars2()
    reminders.showLists()
    //    reminders.showListItems(withName: "Calendar")
    reminders.addEvent()
} else {
    print("You need to grant reminders access")
    exit(1)
}

