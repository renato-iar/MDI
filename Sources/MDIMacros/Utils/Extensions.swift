import Foundation

extension Collection {
    func inRange(_ range: Range<Self.Index>) -> [Element] {
        guard !self.isEmpty else { return [] }

        let lowerBound = Swift.max(startIndex, range.lowerBound)
        let upperBound = Swift.min(endIndex, range.upperBound)

        return Array(self[lowerBound ..< upperBound])
    }

    subscript(safe index: Index) -> Element? {
        guard index >= startIndex, index < endIndex else { return nil }

        return self[index]
    }
}
