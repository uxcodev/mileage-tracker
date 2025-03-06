import SwiftUI

enum ListFilter: String {
    case all
    case trips
    case fillUps
}

struct ContentView: View {
    @StateObject private var store = MileageStore()
    @State private var activeSheet: ActiveSheet?
    @State private var filter: ListFilter = .all
    @State private var searchText = ""
    
    enum ActiveSheet: Identifiable {
        case newTrip
        case newFillUp
        case newFillUpOptions
        
        var id: Int {
            switch self {
            case .newTrip: return 0
            case .newFillUp: return 1
            case .newFillUpOptions: return 2
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $filter) {
                    Text("All").tag(ListFilter.all)
                    Text("Trips").tag(ListFilter.trips)
                    Text("Fill Ups").tag(ListFilter.fillUps)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // List of items
                List {
                    if filter != .fillUps {
                        Section(header: Text("Trips")) {
                            ForEach(store.trips.filter { trip in
                                searchText.isEmpty || 
                                trip.description.localizedCaseInsensitiveContains(searchText)
                            }) { trip in
                                TripRowView(trip: trip, store: store)
                            }
                        }
                    }
                    
                    if filter != .trips {
                        Section(header: Text("Fill-ups")) {
                            ForEach(store.fuelFillUps) { fillUp in
                                FillUpRowView(fillUp: fillUp, store: store)
                            }
                            Button(action: {
                                activeSheet = .newFillUpOptions
                            }) {
                                Label("Add Fill-up", systemImage: "plus")
                            }
                        }
                    }
                }
                
                // Action Buttons
                HStack {
                    Button(action: { activeSheet = .newTrip }) {
                        Label("New Trip", systemImage: "car.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: { activeSheet = .newFillUpOptions }) {
                        Label("New Fill Up", systemImage: "fuelpump.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Mileage Tracker")
            .searchable(text: $searchText, prompt: "Search trips and fill-ups")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .newTrip:
                    NewTripView(store: store)
                case .newFillUp:
                    NewFillUpView(store: store)
                case .newFillUpOptions:
                    NewFillUpInputMethodView(store: store)
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 
