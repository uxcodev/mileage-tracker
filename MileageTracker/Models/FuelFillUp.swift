import Foundation

struct FuelFillUp: Identifiable, Codable, Equatable {
    let id: UUID
    var volume: Double
    var amount: Double
    var location: String
    var odometer: Double
    var date: Date
    
    init(id: UUID = UUID(), 
         volume: Double, 
         amount: Double, 
         location: String, 
         odometer: Double, 
         date: Date = Date()) {
        self.id = id
        self.volume = volume
        self.amount = amount
        self.location = location
        self.odometer = odometer
        self.date = date
    }
    
    var gst: Double {
        return amount * 0.05
    }
    
    static func == (lhs: FuelFillUp, rhs: FuelFillUp) -> Bool {
        lhs.id == rhs.id &&
        lhs.volume == rhs.volume &&
        lhs.amount == rhs.amount &&
        lhs.location == rhs.location &&
        lhs.odometer == rhs.odometer &&
        lhs.date == rhs.date
    }
    
    @MainActor
    class FormData: ObservableObject {
        @Published var volume: String = ""
        @Published var amount: String = ""
        @Published var location: String = ""
        @Published var odometer: String = ""
        
        func toFillUp() -> FuelFillUp {
            FuelFillUp(
                id: UUID(),
                volume: Double(volume) ?? 0,
                amount: Double(amount) ?? 0,
                location: location,
                odometer: Double(odometer) ?? 0,
                date: Date()
            )
        }
    }
} 