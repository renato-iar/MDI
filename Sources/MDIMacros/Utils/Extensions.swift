import Foundation

extension Collection {
    func inRange(_ range: Range<Self.Index>) -> [Element] {
        guard
            range.lowerBound >= startIndex,
            range.upperBound < endIndex
        else {
            return []
        }

        return Array(self[range.lowerBound ..< range.upperBound])
    }
}
