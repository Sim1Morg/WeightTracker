import SwiftUI

struct DataEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var weight: String = ""
    @State private var bodyFat: String = ""
    @State private var muscleMass: String = ""
    @State private var visceralFat: String = ""
    @State private var image: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var weightUnit: WeightUnit = .kg
    @State var entry: Entry? = nil
    @EnvironmentObject var dataManager: DataManager
    @State private var editingMode: Bool = false

    var body: some View {
        NavigationView{
            Form {
                Section(header: Text("Weight")) {
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Body Metrics")) {
                    TextField("Body Fat %", text: $bodyFat)
                        .keyboardType(.decimalPad)
                    TextField("Muscle Mass %", text: $muscleMass)
                        .keyboardType(.decimalPad)
                    TextField("Visceral Fat", text: $visceralFat)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Photo")) {
                    HStack {
                        if let image = image {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } else {
                            Text("No image selected")
                        }
                    }
                    
                    Button("Select Photo") {
                        showingImagePicker = true
                    }
                }
                
                Button("Save") {
                    saveEntry()
                    dismiss()
                }
            }
            .navigationTitle(editingMode ? "Edit Entry" : "Add Entry")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: $inputImage)
            }
            .onAppear {
                loadData()
            }
        }
    }

    // New Initializer for Editing
    init(entry: Entry? = nil, editingMode: Bool = false) {
        _entry = State(initialValue: entry)
        _editingMode = State(initialValue: editingMode)
    }
    
    func loadData() {
        guard let entry = entry else { return }
        weight = String(entry.weight)
        bodyFat = String(entry.bodyFat)
        muscleMass = String(entry.muscleMass)
        visceralFat = String(entry.visceralFat)
        weightUnit = entry.weightUnit
        if let entryImage = entry.image {
            image = Image(uiImage: entryImage)
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }
    
    func saveEntry() {
        guard let weightValue = Double(weight),
              let bodyFatValue = Double(bodyFat),
              let muscleMassValue = Double(muscleMass),
              let visceralFatValue = Int(visceralFat) else {
            return
        }
        let newEntry = Entry(
            date: entry?.date ?? Date(), //if creating an entry, use current date, else use existing entry date
            weight: weightValue,
            bodyFat: bodyFatValue,
            muscleMass: muscleMassValue,
            visceralFat: visceralFatValue,
            weightUnit: weightUnit,
            image: inputImage
        )
        if editingMode {
            dataManager.updateEntry(entry: entry!, updatedEntry: newEntry)
        } else {
            dataManager.addEntry(entry: newEntry)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            
            picker.dismiss(animated: true)
        }
    }
}
