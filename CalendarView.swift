import SwiftUI

struct CalendarView: View {
    @Binding var SelectedDate: Date?
    @State private var CurrentDate = Date()

    var body: some View {
        VStack {
            CalendarHeaderView(CurrentDate: $CurrentDate)
            CalendarGridView(CurrentDate: $CurrentDate, SelectedDate: $SelectedDate)
        }
    }
}

struct CalendarHeaderView: View {
    @Binding var CurrentDate: Date

    var body: some View {
        HStack {
            Button(action: {
                CurrentDate = Calendar.current.date(byAdding: .month, value: -1, to: CurrentDate) ?? CurrentDate
            }) {
                Image(systemName: "arrow.left")
            }
            Spacer()
            Text(CurrentDate, formatter: DateFormatter.monthYearFormatter)
            Spacer()
            Button(action: {
                CurrentDate = Calendar.current.date(byAdding: .month, value: 1, to: CurrentDate) ?? CurrentDate
            }) {
                Image(systemName: "arrow.right")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

struct CalendarGridView: View {
    @Binding var CurrentDate: Date
    @Binding var SelectedDate: Date?

    let DaysInWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(DaysInWeek, id: \.self) { day in
                    Text(day)
                        .fontWeight(.bold)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(0..<NumberOfDaysInMonth() + FirstDayOfMonthWeekday() - 1, id: \.self) { index in
                    if index < FirstDayOfMonthWeekday() - 1 {
                        Text("")
                    } else {
                        let day = index - FirstDayOfMonthWeekday() + 2
                        let date = GetDateForDay(day: day)
                        CalendarDayView(Day: day, Date: date, SelectedDate: $SelectedDate)

                    }
                }
            }

        }
        .padding(.horizontal)
    }

    func NumberOfDaysInMonth() -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: CurrentDate)
        return range?.count ?? 0
    }

    func FirstDayOfMonthWeekday() -> Int {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: CurrentDate)
        components.day = 1
        let firstDayOfMonth = calendar.date(from: components)
        return calendar.component(.weekday, from: firstDayOfMonth!)
    }

    func GetDateForDay(day: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: CurrentDate)
        components.day = day
        return calendar.date(from: components) ?? Date()
    }
}

struct CalendarDayView: View {
    let Day: Int
    let Date: Date
    @Binding var SelectedDate: Date?
    @EnvironmentObject var DataManager: DataManager

    var body: some View {
        Button(action: {
            SelectedDate = Date
        }) {
            ZStack {
                if let SelectedDate = SelectedDate {
                    if Calendar.current.isDate(SelectedDate, inSameDayAs: Date) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
               if DataManager.GetEntry(for: Date) != nil {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 5, height: 5)
                        .offset(x:15, y:-15)
               }

               Text("\(Day)")
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
