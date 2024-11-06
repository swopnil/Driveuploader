import Foundation

struct PathConstructor {
    static func getUploadPath(currency: String, side: String, location: String) -> String {
        let currencyValue = currency.replacingOccurrences(of: "currency/", with: "")
        return "currency/\(currencyValue)/\(currencyValue)\(side)/\(location)"
    }
    
    // Changed to include currency/ prefix
    static func getStatsPath(currency: String, side: String, location: String) -> String {
        let currencyValue = currency.replacingOccurrences(of: "currency/", with: "")
        return "currency/\(currencyValue)/\(currencyValue)\(side)/\(location)"
    }
}
