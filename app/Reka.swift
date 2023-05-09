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
        let (start, end)  = calculateEventsScanWindow()
        
        let eventsToProcess = calendars.fetchEvents(for: calendar, from:start, to: end)
        let allDayEvents = eventsToProcess.filter{i in i.isAllDay}
        let eventsReminderIds = Set(allDayEvents.map{i in i.location ?? ""})
        
        let actualReminders = reminders.fetchNonCompleted(forList: remindersName)
        let actialRemindersIds = Set(actualReminders.map{i in i.calendarItemIdentifier})
        
        let todayStartOfDay = Calendar.current.startOfDay(for: Date.now)
        
        for event in allDayEvents{
            if let reminderId = event.location{
                if actialRemindersIds.contains(reminderId){
                    if event.endDate < todayStartOfDay{
                        let (start, end) = calendars.selectNextEventTime()
                        event.startDate = start
                        event.endDate = end
                        calendars.addEvent(event:event)
                    }
                }else{
                    calendars.removeEvent(event: event)
                }
            }
        }
        
        for reminder in actualReminders {
            if !eventsReminderIds.contains(reminder.calendarItemIdentifier){
                let event = calendars.createEvent(from: reminder, for: calendar)
                calendars.addEvent(event: event)
            }
        }
    }
}
