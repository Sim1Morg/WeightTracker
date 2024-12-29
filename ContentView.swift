import SwiftUI
import CoreData
import PhotosUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    ) private var items: FetchedResults<Item>

    @State private var weight: String = ""
    @State private var selectedUnit = "kg"
    @State private var weightInKg: Double = 0.0
    @State private var muscleMass: String = ""
    @State private var bodyFat: String = ""
    @State private var visceralFat: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isMuscleFieldFocused: Bool
    @FocusState private var isBodyFatFocused: Bool
    @FocusState private var isVisceralFatFocused: Bool
    @State private var selectedImage: PhotosPickerItem?
    @State private var imagePath: String?
    @State private var selectedItem: Item?
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    @State private var isEditing = false

    let units = ["kg", "lbs"]

    var body: some View {
        NavigationView {
            List {
                datePickerSection
                unitPickerSection
                weightTextFieldSection
                muscleMassTextFieldSection
                bodyFatTextFieldSection
                visceralFatTextFieldSection
                imagePickerSection
                createEntryButtonSection
                weightDetailsSection
                itemListSection
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .padding()
        .onChange(of: selectedUnit) {
            updateWeightFromSelectedUnit()
        }
        .task(id: selectedImage) {
            if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                let uiImage = UIImage(data: data)!
                if let newURL = try? saveImage(uiImage) {
                    imagePath = newURL.absoluteString
                }
            }
        }
    }

    // Date Picker Section
    private var datePickerSection: some View {
        Button(action: { showDatePicker.toggle() }) {
            Text("\(selectedDate, format: .dateTime.day().month().year())")
        }
        .sheet(isPresented: $showDatePicker) {
            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .presentationDetents([.medium])
                .onDisappear { showDatePicker = false }
        }
    }

    // Unit Picker Section
    private var unitPickerSection: some View {
        Picker("Unit", selection: $selectedUnit) {
            ForEach(units, id: \.self) { Text($0) }
        }
    }

    // Weight TextField Section
    private var weightTextFieldSection: some View {
        TextField("Enter your weight in \(selectedUnit)", text: $weight)
            .keyboardType(.decimalPad)
            .onChange(of: weight) {
                updateWeightInKg(newValue: weight)
            }
    }

    // Muscle Mass TextField Section
    private var muscleMassTextFieldSection: some View {
        TextField("Enter Muscle Mass %", text: $muscleMass)
            .keyboardType(.decimalPad)
            .focused($isMuscleFieldFocused)
            .onChange(of: isMuscleFieldFocused) {
                if !isMuscleFieldFocused {
                    validatePercentage(value: $muscleMass)
                }
            }
    }

    // Body Fat TextField Section
    private var bodyFatTextFieldSection: some View {
        TextField("Enter Body Fat %", text: $bodyFat)
            .keyboardType(.decimalPad)
            .focused($isBodyFatFocused)
            .onChange(of: isBodyFatFocused) {
                if !isBodyFatFocused {
                    validatePercentage(value: $bodyFat)
                }
            }
    }

    // Visceral Fat TextField Section
    private var visceralFatTextFieldSection: some View {
        TextField("Enter Visceral Fat", text: $visceralFat)
            .keyboardType(.decimalPad)
            .focused($isVisceralFatFocused)
            .onChange(of: isVisceralFatFocused) {
                if !isVisceralFatFocused {
                    validateInteger(value: $visceralFat)
                }
            }
    }

    // Image Picker Section
    private var imagePickerSection: some View {
        PhotosPicker(selection: $selectedImage, matching: .images) {
            Text("Pick Image")
        }
    }

    // Create Entry Button Section
    private var createEntryButtonSection: some View {
        Button("Create entry") {
            createWeightEntry()
        }
    }

    // Weight Details Section
    private var weightDetailsSection: some View {
        VStack {
            Text("Current weight is: \(displayWeight()) \(selectedUnit)")
            Text("Current Muscle Mass: \(muscleMass) %")
            Text("Current Body Fat: \(bodyFat) %")
            Text("Visceral Fat: \(visceralFat)")

            if let imagePath = imagePath {
                Text(imagePath)
            }

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
    }

    // Item List Section
    private var itemListSection: some View {
        ForEach(items) { item in
            VStack(alignment: .leading) {
                Text("\(item.timestamp!, formatter: itemFormatter)")
                    .font(.caption)

                Text("Weight: \(item.weightKg) Kg")
                Text("Body Fat: \(item.bodyFatPercent)")
                Text("Muscle Mass: \(item.muscleMassPercent)")
                Text("Visceral Fat: \(item.visceralFat)")

                if let itemImagePath = item.imagePath {
                    Text(itemImagePath)
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                editButton(item)
            }
            .sheet(isPresented: Binding(
                get: { isEditing && selectedItem?.id == item.id },
                set: { newValue in
                    if !newValue {
                        selectedItem = nil
                    }
                    isEditing = newValue
                }
            )) {
                EditEntryView(item: selectedItem ?? item, onUpdate: { updatedItem in
                    // Update the item using the viewContext, not directly in the list
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        let object = items[index]
                        object.timestamp = updatedItem.timestamp
                        object.weightKg = updatedItem.weightKg
                        object.muscleMassPercent = updatedItem.muscleMassPercent
                        object.bodyFatPercent = updatedItem.bodyFatPercent
                        object.visceralFat = updatedItem.visceralFat
                        object.imagePath = updatedItem.imagePath
                        
                        // Save the updated context
                        do {
                            try viewContext.save()
                        } catch {
                            showError(message: "Failed to save changes: \(error.localizedDescription)")
                        }
                    }
                    isEditing = false
                })
            }
        }
        .onDelete(perform: deleteItems)
    }

    // Edit Button
    private func editButton(_ item: Item) -> some View {
        Button("Edit") {
            isEditing = true
            selectedItem = item
        }
        .tint(.blue)
    }

    private func createWeightEntry() {
        guard let weightValue = Double(weight) else {
            return showError(message: "Weight must be numeric.")
        }
        guard let muscleMassValue = Double(muscleMass) else {
            return showError(message: "Muscle mass must be numeric.")
        }
        guard let bodyFatValue = Double(bodyFat) else {
            return showError(message: "Body Fat must be numeric.")
        }
        guard let visceralFatValue = Int(visceralFat) else {
            return showError(message: "Visceral Fat must be an integer.")
        }

        if selectedDate > Date() {
            return showError(message: "Date must not be in the future.")
        }

        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = selectedDate
            newItem.weightKg = weightValue
            newItem.muscleMassPercent = muscleMassValue
            newItem.bodyFatPercent = bodyFatValue
            newItem.visceralFat = Int64(visceralFatValue)
            newItem.imagePath = imagePath

            do {
                try viewContext.save()
            } catch {
                showError(message: "Failed to save item: \(error.localizedDescription)")
            }
        }
    }

    private func saveImage(_ uiImage: UIImage) throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("MyImage\(UUID().uuidString).jpg")
        guard let data = uiImage.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ImageError", code: 2)
        }
        try data.write(to: fileURL)
        return fileURL
    }

    private func validatePercentage(value: Binding<String>) {
        if let percentage = Double(value.wrappedValue), percentage < 0 || percentage > 100 {
            showError(message: "Value must be between 0 and 100.")
            value.wrappedValue = ""
        } else if value.wrappedValue != "" && Double(value.wrappedValue) == nil {
            showError(message: "Invalid number format.")
            value.wrappedValue = ""
        }
    }

    private func validateInteger(value: Binding<String>) {
        if let number = Double(value.wrappedValue), number < 0 {
            showError(message: "Value must not be negative.")
            value.wrappedValue = ""
        } else if value.wrappedValue != "" && Double(value.wrappedValue) == nil {
            showError(message: "Invalid number format.")
            value.wrappedValue = ""
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showError = false
        }
    }

    private func updateWeightInKg(newValue: String) {
        if let weightValue = Double(newValue) {
            weightInKg = selectedUnit == "kg" ? weightValue : lbsToKg(lbs: weightValue)
        }
    }

    private func lbsToKg(lbs: Double) -> Double {
        return lbs * 0.453592
    }

    private func kgToLbs(kg: Double) -> Double {
        return kg * 2.20462
    }

    private func displayWeight() -> String {
        let weightForDisplay = selectedUnit == "kg" ? weightInKg : kgToLbs(kg: weightInKg)
        return String(format: "%.1f", weightForDisplay)
    }

    private func updateWeightFromSelectedUnit() {
        weight = displayWeight()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                showError(message: "Failed to delete item: \(error.localizedDescription)")
            }
        }
    }

    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

