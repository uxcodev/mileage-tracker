import Foundation
import SwiftUI

class MileageStore: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var fuelFillUps: [FuelFillUp] = []
    @Published var initialOdometer: Double?
    @Published var initialOdometerDate: Date?
    
    init() {
        // Create a date formatter for our input
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d/yy"
        
        // Initial odometer reading
        initialOdometer = 209450
        initialOdometerDate = dateFormatter.date(from: "Nov 23/24")
        
        // Add all fuel fillups
        let fillUps: [(date: String, amount: Double, volume: Double, odometer: Double, location: String)] = [
            ("Nov 23/24", 144.04, 85.028, 209516, "Abbotsford"),
            ("Dec 5/24", 115.00, 68.9, 210308, "Lake Country"),
            ("Dec 11/24", 95.00, 57.613, 211173, "Abbotsford"),
            ("Dec 12/24", 50.12, 29.498, 211505, "Lake Country"),
            ("Dec 27/24", 113.00, 70.686, 212318, "Fernie"),
            ("Jan 12/25", 114.00, 63.723, 213051, "Vernon"),
            ("Feb 2/25", 78.00, 43.604, 213499, "Vernon"),
            ("Feb 6/25", 105.00, 57.095, 214156, "Abbotsford"),
            ("Feb 17/25", 77.00, 47.267, 214700, "Kelowna"),
            ("Feb 27/25", 108.00, 62.284, 215282, "Abbotsford"),
            ("Feb 27/25", 56.00, 32.597, 215648, "Lake Country")
        ]
        
        // Add all fillups
        for fillUp in fillUps {
            if let date = dateFormatter.date(from: fillUp.date) {
                fuelFillUps.append(FuelFillUp(
                    id: UUID(),
                    volume: fillUp.volume,
                    amount: fillUp.amount,
                    location: fillUp.location,
                    odometer: fillUp.odometer,
                    date: date
                ))
            }
        }
        
        // Add the Dec 9 trip
        if let tripDate = dateFormatter.date(from: "Dec 9/24") {
            trips.append(Trip(
                startDate: tripDate,
                startOdometer: 210524,
                description: "Lake Country - 50L"
            ))
        }
    }
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
    }
    
    func addFuelFillUp(volume: Double, amount: Double, location: String, odometer: Double) {
        let fillUp = FuelFillUp(
            volume: volume,
            amount: amount,
            location: location,
            odometer: odometer
        )
        fuelFillUps.append(fillUp)
    }
    
    func updateTrip(startDate: Date, startOdometer: Double, endDate: Date?, endOdometer: Double?, description: String, tripId: UUID) {
        if let index = trips.firstIndex(where: { $0.id == tripId }) {
            trips[index] = Trip(
                id: tripId,  // Preserve the original ID
                startDate: startDate,
                startOdometer: startOdometer,
                endDate: endDate,
                endOdometer: endOdometer,
                description: description
            )
        }
    }
    
    func updateFillUp(id: UUID, volume: Double, amount: Double, location: String, odometer: Double) {
        if let index = fuelFillUps.firstIndex(where: { $0.id == id }) {
            fuelFillUps[index] = FuelFillUp(
                id: id,
                volume: volume,
                amount: amount,
                location: location,
                odometer: odometer
            )
        }
    }

     func deleteFillUp(_ fillUp: FuelFillUp) {
        fuelFillUps.removeAll { $0.id == fillUp.id }
    }
} 