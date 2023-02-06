//
//  ContentView.swift
//  EventCounter
//
//  Created by Renan Greca on 02/02/23.
//

import SwiftUI
import CoreData
import EventKit

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    var eventsCalendarManager = EventsCalendarManager()

    @State private var eventCalendar: EKCalendar?
    @State private var reminderCalendar: EKCalendar?
    @State private var eventName: String = ""
    @State private var count: Double = 0.0
    @State var calendars = [EKEntityType.event: [EKCalendar](), EKEntityType.reminder: [EKCalendar]()]
    @State private var reminders: [EKReminder] = []
    @State private var reminder: EKReminder?
//    @State var reminderCalendars: [EKCalendar]
    
    var body: some View {
        
        VStack {
            
            Picker(selection: $eventCalendar, content: {
                ForEach(self.calendars[.event]!, id: \.calendarIdentifier) { calendar in
                    Text(calendar.title).tag(EKCalendar?.some(calendar))
                }
            }, label: {
                Text("Calendar")
            }).onAppear {
                self.getCalendars(for: .event)
            }
            
            Picker(selection: $reminderCalendar, content: {
                ForEach(self.calendars[.reminder]!, id: \.calendarIdentifier) { calendar in
                    Text(calendar.title).tag(EKCalendar?.some(calendar))
                }
            }, label: {
                Text("Reminder List")
            }).onAppear {
                self.getCalendars(for: .reminder)
            }.onChange(of: reminderCalendar) { _ in
                self.searchReminders()
            }
            
            Picker(selection: $reminder, content: {
                ForEach(self.reminders, id: \.calendarItemIdentifier) { reminder in
                    Text(reminder.title).tag(EKReminder?.some(reminder))
                }
            }, label: {
                Text("Reminder")
            }).onChange(of: reminder) { _ in
                self.search()
            }
            Text("Status: \((self.reminder?.isCompleted ?? false) ? "Complete" : "Incomplete" )")
            Text("\(String(format: "%.2f", self.count)) hours on record")
        }
        
    }
    
    
    struct SettingsButton: View {
        @State var pushed: Bool = false
        
        var body: some View {
            Button(action: {
                self.pushed = true
            }, label: {
                Image(systemName: "plus")
                .resizable()
                .frame(width: 22, height: 22)
                
            })
                .sheet(isPresented: $pushed) {
                    AddItemView()
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.name = ""

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func getCalendars(for type: EKEntityType) {
        if self.calendars[type]!.count == 0 {
            
            eventsCalendarManager.checkAuthorization(for: type) { result in
                if result {
                    self.calendars[type]! = eventsCalendarManager.listCalendars(for: type)
                }
            }
            
        }
    }
    
    private func searchReminders() {
        if let calendar = self.reminderCalendar {
            eventsCalendarManager.findReminders(in: calendar) { reminders in
                self.reminders = reminders
            }
        }
    }
    
    private func search() {
        if let reminderTitle = self.reminder?.title {
            self.count = eventsCalendarManager.findNamedEvents(eventTitle: reminderTitle,
                                                               calendar: self.eventCalendar)
                .reduce(0, { a, b in
                    // Add up cumulative hours spent in activity
                    a + (b.endDate.timeIntervalSince(b.startDate) / 3600)
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        let calendar = EKCalendar(for: .event, eventStore: EKEventStore())
        calendar.title = "ABC"

        return ContentView(calendars: [.event: [calendar], .reminder: [calendar]]).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
