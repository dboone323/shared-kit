import Foundation

@available(macOS 12.0, iOS 15.0, *)
public class MockURLSession: URLSession, @unchecked Sendable {
    override public init() {}

    // We can't easily override the async data(for:) method in a way that works perfectly with standard URLSession
    // because it's non-open in Swift/ObjC in some contexts or hard to subclass correctly.
    // A better approach for Swift testing is using URLProtocol.
}

// Better Approach: MockURLProtocol
@available(macOS 12.0, iOS 15.0, *)
public class MockURLProtocol: URLProtocol {
    private class State: @unchecked Sendable {
        var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    }
    private static let state = State()
    private static let lock = NSLock()

    public static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return state.handler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            state.handler = newValue
        }
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override public func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            // Default failure if no handler
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {}
}
