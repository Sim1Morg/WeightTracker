import SwiftUI

@main
struct WeightTrackerApp: App {
  
   @StateObject private var DataManager = DataManager()

  var body: some Scene {
      WindowGroup {
          ContentView()
              .environmentObject(DataManager)
      }
  }
}
