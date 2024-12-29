import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date?
    @State private var currentDate = Date()
    
    var body: some View {
        VStack {
            CalendarHeaderView(currentDate: $currentDate)
            CalendarGridView(currentDate: $currentDate, selectedDate: $selectedDate)
        }
    }
}

struct CalendarHeaderView: View {
    @Binding var currentDate: Date
    
    var body: some View {
        HStack {
            Button(action: {
                currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
            }) {
                Image(systemName: "arrow.left")
            }
            Spacer()
            Text(currentDate, formatter: DateFormatter.monthYearFormatter)
            Spacer()
            Button(action: {
                currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }) {
                Image(systemName: "arrow.right")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

struct CalendarGridView: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date?
    
    let daysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysInWeek, id: \.self) { day in
                    Text(day)
                        .fontWeight(.bold)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(0..<numberOfDaysInMonth() + firstDayOfMonthWeekday() - 1, id: \.self) { index in
                    if index < firstDayOfMonthWeekday() - 1 {
                        Text("")
                    } else {
                        let day = index - firstDayOfMonthWeekday() + 2
                        let date = getDateForDay(day: day)
                        CalendarDayView(day: day, date: date, selectedDate: $selectedDate)
                        
                    }
                }
            }
            
        }
        .padding(.horizontal)
    }
    
    func numberOfDaysInMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: currentDate)
        return range?.count ?? 0
    }
    
    func firstDayOfMonthWeekday() -> Int {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = 1
        let firstDayOfMonth = calendar.date(from: components)
        return calendar.component(.weekday, from: firstDayOfMonth!)
    }
    
    func getDateForDay(day: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = day
        return calendar.date(from: components) ?? Date()
    }
}

struct CalendarDayView: View {
    let day: Int
    let date: Date
    @Binding var selectedDate: Date?
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Button(action: {
            selectedDate = date
        }) {
            ZStack {
                if let selectedDate = selectedDate {
                    if Calendar.current.isDate(selectedDate, inSameDayAs: date) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
               if dataManager.getEntry(for: date) != nil {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 5, height: 5)
                        .offset(x:15, y:-15)
               }

               Text("\(day)")
                   .foregroundColor(.primary)
            }
            .frame(width: 40, height: 40)
        }
    }
}


extension DateFormatter {
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}
