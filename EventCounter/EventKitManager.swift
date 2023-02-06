//
//  EventKitManager.swift
//  EventCounter
//
//  Created by Renan Greca on 02/02/23.
//

import EventKit

//typealias EventsCalendarManagerResponse = (_ result: ResultCustomError<Bool, CustomError>) -> Void

class EventsCalendarManager: NSObject {
    
    var eventStore: EKEventStore!
    
    let today = Date()
    let oneYearAgo = Date(timeIntervalSinceNow: TimeInterval( (60*60*24*365*(-1)) )) // Current date - number of seconds in one year
    
    override init() {
        eventStore = EKEventStore()
    }
    
    func checkAuthorization(for type: EKEntityType, completion: @escaping (_ result: Bool) -> Void ) {
        let typeName = type == .event ? "Event" : "Reminder";
        
        switch getAuthorizationStatus(for: type) {
        case .authorized:
            print("\(typeName) access previously granted")
            completion(true)
        case .notDetermined:
            //Auth is not determined
            //We should request access to the calendar
            requestAccess(to: type) { (accessGranted, error) in
                if accessGranted {
                    print("\(typeName) access granted")
                    completion(true)
                } else {
                    print("\(typeName) access denied")
                    completion(false)
                }
            }
        case .denied, .restricted:
            print("\(typeName) access previously denied")
            completion(false)
        default:
            completion(false)
        }
    }
    
    /// Request access to the Calendar
    private func requestAccess(to type: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        eventStore.requestAccess(to: type) { (accessGranted, error) in
            completion(accessGranted, error)
        }
    }
    
    /// Get Calendar auth status
    private func getAuthorizationStatus(for type: EKEntityType) -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: type)
    }
    
    func findNamedEvents(eventTitle: String, calendar: EKCalendar?) -> [EKEvent] {
        let calendars = (calendar != nil ? [calendar!] : [])
        let predicate = eventStore.predicateForEvents(withStart: oneYearAgo, end: today, calendars: calendars)
        let events = eventStore.events(matching: predicate) as NSArray
        let textPredicate = NSPredicate(format: "title like '\(eventTitle)'")
        let results = events.filtered(using: textPredicate) as! [EKEvent]
        
        return results
        
                                    
//        var results = [EKEvent]()
//        eventStore.enumerateEvents(matching: predicate, using: { event, _ in
//            // EKEventStore does not allow us to search event by title, so we go through the listed events and store the ones with matching titles.
//            if event.title == eventTitle {
//                results.append(event)
//            }
//        })
//
//        return results
    }
    
    func findReminders(in calendar: EKCalendar, completion: @escaping (_ reminders: [EKReminder]) -> Void ) {
        let predicate = eventStore.predicateForReminders(in: [calendar])
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            if let reminders = reminders {
                completion(reminders)
            }
        }
        
    }
    
    func listCalendars(for type: EKEntityType) -> [EKCalendar] {
        
        return eventStore.calendars(for: type)//.map { $0.title }
        
    }
    
}
