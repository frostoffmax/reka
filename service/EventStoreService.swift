//
//  EventStoreService.swift
//  reka
//
//  Created by Maksim Morozov on 22.04.2023.
//

import Foundation
import EventKit

public class EvenStoreService {
    let entityType: EKEntityType
    let store: EKEventStore
    
    init(type: EKEntityType){
        self.entityType = type
        self.store = EKEventStore()
    }
    
    func requestAccess() -> Bool{
        let semaphore = DispatchSemaphore(value: 0)
        var grantedAccess = false
        store.requestAccess(to: entityType) { granted, _ in
            grantedAccess = granted
            semaphore.signal()
        }
        semaphore.wait()
        
        return grantedAccess
    }
    
    func fetchCalendar(withName name: String) -> EKCalendar {
        if let calendar = self.fetchAllCalendars().first(where: { $0.title.lowercased() == name.lowercased() }) {
            return calendar
        } else {
            print("No reminders list matching \(name)")
            exit(1)
        }
    }
    
    func fetchAllCalendars() -> [EKCalendar] {
        return store.calendars(for: entityType)
            .filter { $0.allowsContentModifications }
    }
}
