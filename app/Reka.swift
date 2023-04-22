//
//  Reka.swift
//  reka
//
//  Created by Maksim Morozov on 22.04.2023.
//

import Foundation

class Reka {
    let reminders: RemindersService
    let calendars: CalendarService
    
    init(reminders: RemindersService, calendars: CalendarService){
        self.reminders = reminders
        self.calendars = calendars
    }
    
    func runSync(remindersName: String, calendarName: String){
        let calendar = calendars.fetchCalendar(withName: calendarName)
        
        let startOfDay = Calendar.current.startOfDay(for: Date.now)
        let startOfNextWeekComponents = DateComponents(day:7, second: -1)
        let endOfWeekDay = Calendar.current.date(byAdding: startOfNextWeekComponents, to: startOfDay)!
        
        let todayEvents = calendars.fetchEvents(for: calendar, from:startOfDay, to: endOfWeekDay)
        let toadyAllDayEvents = todayEvents.filter{i in i.isAllDay}
        let eventsReminderIds = Set(toadyAllDayEvents.map{i in i.notes ?? ""})
        
        let actualReminders = reminders.fetchNonCompleted(forList: remindersName)
        let actialRemindersIds = Set(actualReminders.map{i in i.calendarItemIdentifier})
        
        var eventsToCreate = Set(actialRemindersIds)
        eventsToCreate.subtract(eventsReminderIds)
        print("eventsToCreate \(eventsToCreate)")
        
        for reminder in actualReminders{
            if !eventsToCreate.contains(reminder.calendarItemIdentifier){
                continue
            }
            let event = calendars.createEvent(from: reminder, for: calendar)
            calendars.addEvent(event: event)
        }
        
        
        var eventToRemove = Set(eventsReminderIds)
        eventToRemove.subtract(actialRemindersIds)
        print("eventToRemove \(eventToRemove)")
        
        for event in toadyAllDayEvents{
            if let reminderId = event.notes {
                if eventToRemove.contains(reminderId){
                    calendars.removeEvent(event: event)
                }
            }
        }
    }
}
