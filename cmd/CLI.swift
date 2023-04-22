//
//  CLI.swift
//  reka
//
//  Created by Maksim Morozov on 22.04.2023.
//

import Foundation
import ArgumentParser

func accessOrExit(service: EvenStoreService){
    if !service.requestAccess(){
        print("Access to \(service.entityType) denied")
        exit(1)
    }
}

struct CLI: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName:"reka",
        abstract: "Sync remindes list with calendar"
    )
    
    @Argument(help: "Reminders list name to sync with calendar")
    var remindersList: String
    
    @Argument(help: "Calendar name that will be use to sync")
    var calendarName: String
    
    func run() throws {
        let reminders = RemindersService()
        let calendars = CalendarService()

        accessOrExit(service: reminders)
        accessOrExit(service: calendars)

        let app = Reka(reminders: reminders, calendars: calendars)
        app.runSync(remindersName: remindersList, calendarName: calendarName)
    }
}
