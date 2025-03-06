import Foundation

struct ParsedFillUp {
    var volume: Double = 0
    var amount: Double = 0
    var location: String = ""
    var odometer: Double = 0
}

class TranscriptParser {
    static func parse(_ transcript: String) -> ParsedFillUp {
        var result = ParsedFillUp()
        let text = transcript.lowercased()
        
        // Volume parsing (looking for numbers followed by liters/L)
        if let volumeMatch = text.firstMatch(of: /(\d+(?:\.\d+)?)\s*(?:liters?|l\b)/) {
            result.volume = Double(volumeMatch.1) ?? 0
        }
        
        // Amount parsing (looking for dollar amounts)
        if let amountMatch = text.firstMatch(of: /(?:\$\s*)?(\d+(?:\.\d+)?)\s*(?:dollars?|(?=\s|$))/) {
            result.amount = Double(amountMatch.1) ?? 0
        }
        
        // Location parsing (looking for "in" followed by location)
        if let locationMatch = text.firstMatch(of: /\bin\s+([^.]+?)(?:\s+for|\.|$)/) {
            result.location = locationMatch.1.trimmingCharacters(in: .whitespaces).capitalized
        }
        
        // Odometer parsing (looking for numbers followed by km/kilometers)
        if let odometerMatch = text.firstMatch(of: /(\d+(?:,\d{3})*(?:\.\d+)?)\s*(?:km|kilometers?)/) {
            let numberStr = odometerMatch.1.replacingOccurrences(of: ",", with: "")
            result.odometer = Double(numberStr) ?? 0
        }
        
        return result
    }
} 