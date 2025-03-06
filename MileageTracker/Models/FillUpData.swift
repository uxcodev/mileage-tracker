import Foundation

public struct FillUpData: Equatable {
    public var volume: Double? = nil
    public var amount: Double? = nil
    public var location: String = ""
    public var odometer: Double? = nil
    
    public init(volume: Double? = nil, amount: Double? = nil, location: String = "", odometer: Double? = nil) {
        self.volume = volume
        self.amount = amount
        self.location = location
        self.odometer = odometer
    }
    
    public var isEmpty: Bool {
        volume == nil && amount == nil && location.isEmpty && odometer == nil
    }
    
    public static func fromSpeechTranscript(_ transcript: String) -> FillUpData {
        var data = FillUpData()
        let words = transcript.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        var i = 0
        while i < words.count {
            let word = words[i]
            
            // Parse odometer
            if let number = Double(word.replacingOccurrences(of: ",", with: "")),
               i + 1 < words.count && (words[i + 1] == "km" || words[i + 1] == "kilometers") {
                data.odometer = number
                i += 2
                continue
            }
            
            // Parse volume
            if let number = Double(word),
               i + 1 < words.count && (words[i + 1] == "l" || words[i + 1] == "liters") {
                data.volume = number
                i += 2
                continue
            }
            
            // Parse amount
            if word.hasPrefix("$") || (i + 1 < words.count && words[i + 1].hasPrefix("$")) {
                let amountStr = word.hasPrefix("$") ? word.dropFirst() : words[i + 1].dropFirst()
                if let number = Double(amountStr.replacingOccurrences(of: ",", with: "")) {
                    data.amount = number
                    i += word.hasPrefix("$") ? 1 : 2
                    continue
                }
            }
            
            // Parse city
            if word == "in" && i + 1 < words.count {
                data.location = words[i + 1].capitalized
                i += 2
                continue
            }
            
            i += 1
        }
        
        return data
    }
} 
