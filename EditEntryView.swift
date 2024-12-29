import SwiftUI

struct EditEntryView: View {
    @Environment(\.dismiss) var Dismiss
    @State private var Weight: String = ""
    @State private var BodyFat: String = ""
    @State private var MuscleMass: String = ""
    @State private var VisceralFat: String = ""
    @State private var Image: Image? = nil
    @State private var InputImage: UIImage? = nil
    @State private var ShowingImagePicker = false
    @State private var WeightUnit: WeightUnit = .kg
    @State var Entry: Entry? = nil
    @EnvironmentObject var DataManager: DataManager
    @State private var EditingMode: Bool = false

    var body: some View {
        NavigationView{
            Form {
                Section(header: Text("Weight")) {
                    TextField("Weight", text: $Weight)
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $WeightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Body Metrics")) {
                    TextField("Body Fat %", text: $BodyFat)
                        .keyboardType(.decimalPad)
                    TextField("Muscle Mass %", text: $MuscleMass)
                        .keyboardType(.decimalPad)
                    TextField("Visceral Fat", text: $VisceralFat)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Photo")) {
                    HStack {
                        if let Image = Image {
                            Image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        } else {
                            Text("No image selected")
                        }
                    }

                    Button("Select Photo") {
                        ShowingImagePicker = true
                    }
                }

                Button("Save") {
                    SaveEntry()
                    Dismiss()
                }
            }
            .navigationTitle(EditingMode ? "Edit Entry" : "Add Entry")
            .sheet(isPresented: $ShowingImagePicker, onDismiss: LoadImage) {
                ImagePicker(Image: $InputImage)
            }
            .onAppear {
                LoadData()
            }
        }
    }

    // New Initializer for Editing
    init(Entry: Entry? = nil, EditingMode: Bool = false) {
        _Entry = State(initialValue: Entry)
        _EditingMode = State(initialValue: EditingMode)
    }

    func LoadData() {
        guard let Entry = Entry else { return }
        Weight = String(Entry.Weight)
        BodyFat = String(Entry.BodyFat)
        MuscleMass = String(Entry.MuscleMass)
        VisceralFat = String(Entry.VisceralFat)
        WeightUnit = Entry.WeightUnit
        if let EntryImage = Entry.Image {
            Image = SwiftUI.Image(uiImage: EntryImage)
        }
    }

    func LoadImage() {
        guard let InputImage = InputImage else { return }
        Image = SwiftUI.Image(uiImage: InputImage)
    }

    func SaveEntry() {
        guard let WeightValue = Double(Weight),
              let BodyFatValue = Double(BodyFat),
              let MuscleMassValue = Double(MuscleMass),
              let VisceralFatValue = Int(VisceralFat) else {
            return
        }
        let NewEntry = Entry(
            Date: Entry?.Date ?? Date(), //if creating an entry, use current date, else use existing entry date
            Weight: WeightValue,
            BodyFat: BodyFatValue,
            MuscleMass: MuscleMassValue,
            VisceralFat: VisceralFatValue,
            WeightUnit: WeightUnit,
            Image: InputImage
        )
        if EditingMode {
            DataManager.UpdateEntry(Entry: Entry!, UpdatedEntry: NewEntry)
        } else {
            DataManager.AddEntry(Entry: NewEntry)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var Image: UIImage?

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
                parent.Image = uiImage
            }

            picker.dismiss(animated: true)
        }
    }
}
