//
//  EventsService.swift
//  reka
//
//  Created by Maksim Morozov on 22.04.2023.
//

import Foundation
import EventKit

class CalendarService: EvenStoreService{
    init(){
        super.init(type: .event)
    }
    
    func fetchEvents(for calendar:EKCalendar, from :Date, to: Date) -> [EKEvent]
    {
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: [calendar])
        return store.events(matching: predicate)
    }
    
    private func calcStartDate(forReminder rem: EKReminder) -> Date{
        let now = Date.now
        
        if let remComponents = rem.dueDateComponents {
            let remDueDate = Calendar.current.date(from: remComponents)!
            
            if remDueDate > now {
                return remDueDate
            }
        }
        
        return now
    }
    
    func createEvent(from reminder: EKReminder, for calendar: EKCalendar) -> EKEvent{
        let ev = EKEvent(eventStore: store)
        ev.calendar = calendar
        ev.title = reminder.title
        ev.notes = reminder.calendarItemIdentifier
        ev.isAllDay = true
        ev.startDate = calcStartDate(forReminder: reminder)
        
        let timeSpan = DateComponents(minute: 15)
        let endDate = Calendar.current.date(byAdding: timeSpan, to: ev.startDate)
        ev.endDate = endDate
        
        return ev
    }
    
    func removeEvent(event: EKEvent){
        do{
            try store.remove(event, span: .thisEvent, commit: true)
        }catch let error {
            print("Failed to remove reminder with error: \(error)")
        }
    }
    
    func addEvent(event: EKEvent){
        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch let error {
            print("Failed to save reminder with error: \(error)")
        }
    }
}
