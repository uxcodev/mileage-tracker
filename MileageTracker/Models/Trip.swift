import Foundation

struct Trip: Identifiable {
    let id: UUID
    let startDate: Date
    let startOdometer: Double
    var endDate: Date?
    var endOdometer: Double?
    let description: String
    
    init(
        id: UUID = UUID(),  // Default to new UUID if not provided
        startDate: Date,
        startOdometer: Double,
        endDate: Date? = nil,
        endOdometer: Double? = nil,
        description: String
    ) {
        self.id = id
        self.startDate = startDate
        self.startOdometer = startOdometer
        self.endDate = endDate
        self.endOdometer = endOdometer
        self.description = description
    }
    
    var isInProgress: Bool {
        return endDate == nil
    }
    
    var distance: Double? {
        guard let endOdometer = endOdometer else { return nil }
        return endOdometer - startOdometer
    }
} 