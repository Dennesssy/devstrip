import Foundation

struct FileSizeFormatter {
    
    /// Formats bytes into a human-readable string (B, KB, MB, GB, TB)
    static func formattedString(fromBytes bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    /// Formats bytes with specific precision
    static func formattedString(fromBytes bytes: Int64, precision: Int = 2) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        
        let formatted = formatter.string(fromByteCount: bytes)
        
        // Adjust precision if needed
        if precision >= 0 {
            // Remove excessive decimal places
            let components = formatted.components(separatedBy: " ")
            if components.count == 2 {
                let number = components[0]
                let unit = components[1]
                
                if let decimalIndex = number.firstIndex(of: ".") {
                    let beforeDecimal = number.prefix(upTo: decimalIndex)
                    let afterDecimal = number.suffix(from: decimalIndex).dropFirst()
                    
                    let trimmedDecimal = String(afterDecimal.prefix(precision))
                    let formattedNumber = beforeDecimal + (trimmedDecimal.isEmpty ? "" : ".\(trimmedDecimal)")
                    return "\(formattedNumber) \(unit)"
                }
            }
        }
        
        return formatted
    }
    
    /// Returns the appropriate unit for the given byte count
    static func unit(forBytes bytes: Int64) -> String {
        let absBytes = abs(bytes)
        
        if absBytes < 1024 {
            return "B"
        } else if absBytes < 1024 * 1024 {
            return "KB"
        } else if absBytes < 1024 * 1024 * 1024 {
            return "MB"
        } else if absBytes < 1024 * 1024 * 1024 * 1024 {
            return "GB"
        } else {
            return "TB"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let modificationDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
