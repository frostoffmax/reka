//
//  Reka.swift
//  reka
//
//  Created by Maksim Morozov on 22.04.2023.
//

import Foundation
import EventKit

class Reka {
    let reminders: RemindersService
    let calendars: CalendarService
    
    init(reminders: RemindersService, calendars: CalendarService){
        self.reminders = reminders
        self.calendars = calendars
    }
    
    func calculateEventsScanWindow() -> (Date, Date){
        let todayStartOfDay = Calendar.current.startOfDay(for: Date.now)
        
        let yesterdayStartComponents = DateComponents(day: -1)
        let startOfNextWeekComponents = DateComponents(day:7, second: -1)
        
        let from = Calendar.current.date(byAdding: yesterdayStartComponents, to: todayStartOfDay)!
        let to = Calendar.current.date(byAdding: startOfNextWeekComponents, to: todayStartOfDay)!
        
        return (from, to)
    }
    
    func runSync(remindersName: String, calendarName: String){
        let calendar = calendars.fetchCalendar(withName: calendarName)
        let (startScanDate, endScanDate)  = calculateEventsScanWindow()
        
        let currentEvents = calendars.fetchEvents(for: calendar, from:startScanDate, to: endScanDate)
            .lazy
            .filter{i in i.isAllDay && !(i.location ?? "").isEmpty}
            .reduce(
                into: [String:EKEvent](),
                { dict, event in dict[event.location!] = event }
            )
        
        let currentReminders = reminders.fetchNonCompleted(forList: remindersName)
            .lazy
            .reduce(into: [String:EKReminder](),
                    { dict, reminder in dict[reminder.calendarItemIdentifier] = reminder }
            )
        
        let todayStartOfDay = Calendar.current.startOfDay(for: Date.now)
        
        for eventId in currentEvents.keys{
            if !currentReminders.keys.contains(eventId){
                calendars.removeEvent(event: currentEvents[eventId]!)
            }
        }
        
        for (reminderId, reminder) in currentReminders {
            if !currentEvents.keys.contains(reminderId){
                let event = calendars.createEvent(from: reminder, for: calendar)
                if event.endDate < endScanDate{
                    calendars.addEvent(event: event)
                }
                continue
            }
            
            let event = currentEvents[reminder.calendarItemIdentifier]!
            if event.endDate < todayStartOfDay{
                let (start, end) = calendars.selectNextEventTime()
                event.startDate = start
                event.endDate = end
                calendars.addEvent(event:event)
            }
        }
    }
}
