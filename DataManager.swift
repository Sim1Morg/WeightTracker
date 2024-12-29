import SwiftUI

struct ContentView: View {
    @EnvironmentObject var DataManager: DataManager
    @State private var ShowingAddEntry = false
    @State private var SelectedDate: Date? = nil
    @State private var ShowEditEntry = false
    @State private var SelectedEntry: Entry? = nil

    var body: some View {
        NavigationView {
            VStack {
                CalendarView(SelectedDate: $SelectedDate)
                if let SelectedDate = SelectedDate {
                    if let entry = DataManager.GetEntry(for: SelectedDate) {
                        Text("Weight: \(entry.Weight)")
                        Text("Body Fat: \(entry.BodyFat)")
                        Text("Muscle Mass: \(entry.MuscleMass)")
                        Text("Visceral Fat: \(entry.VisceralFat)")
                        if let image = entry.Image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                        }

                        Button("Edit Entry") {
                            SelectedEntry = entry
                            ShowEditEntry = true
                        }
                    } else {
                       Text("No Entry for this date")
                    }
                }
            }
            .navigationTitle("Weight Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        ShowingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
            .sheet(isPresented: $ShowingAddEntry) {
                EditEntryView()
            }
            .sheet(isPresented: $ShowEditEntry) {
                if let SelectedEntry = SelectedEntry {
                    EditEntryView(Entry: SelectedEntry, EditingMode: true)
               }
             }
        }
    }
}
