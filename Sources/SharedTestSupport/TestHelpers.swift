import Foundation

public enum TestHelpers {
    // Simple wait-for condition with timeout for async UI/testing
    @discardableResult
    public static func wait(seconds: TimeInterval) -> Bool {
        let until = Date().addingTimeInterval(seconds)
        while Date() < until {
            RunLoop.current.run(mode: .default, before: until)
        }
        return true
    }

    /// Load a JSON fixture bundled with tests. Provide a bundle explicitly; defaults to main when not running in SPM tests.
    public static func loadJSONFixture(name: String, bundle: Bundle? = nil) throws -> Data {
        let resolvedBundle = bundle ?? Bundle(for: BundleMarker.self) ?? .main
        guard let url = resolvedBundle.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "SharedTestSupport", code: 404, userInfo: [NSLocalizedDescriptionKey: "Missing fixture: \(name).json"])
        }
        return try Data(contentsOf: url)
    }
}

// Marker type to locate bundle in XCTest contexts
private final class BundleMarker {}
