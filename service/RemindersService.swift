//
//  RemindersService.swift
//  reka
//
//  Created by Maksim Morozov on 22.04.2023.
//

import Foundation

import EventKit

class RemindersService : EvenStoreService {
    init(){
        super.init(type: .reminder)
    }

    func fetchListItems(forList name:String) -> [EKReminder]{
        let cal = fetchCalendar(withName: name)
        let semaphore = DispatchSemaphore(value: 0)
        let predicate = store.predicateForReminders(in: [cal])
        
        var rems: [EKReminder] = []
        store.fetchReminders(matching: predicate) {reminders in
            rems.append(contentsOf:(reminders ?? []))
            semaphore.signal()
        }
        
        semaphore.wait()
        return rems
    }

    func fetchNonCompleted(forList name: String) -> [EKReminder]{
        return fetchListItems(forList: name).filter{ !$0.isCompleted }
    }

    func fetchAllLists(){
        let cals = fetchAllCalendars()
        for cal in cals{
            print(cal.title)
        }
    }
}
