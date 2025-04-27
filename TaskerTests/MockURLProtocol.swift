import Foundation
import XCTest

// MARK: - Mock URLProtocol for Network Testing

class MockURLProtocol: URLProtocol {
    static var mockResponses = [URL: Result<(HTTPURLResponse, Data), Error>]()
    static var lastCapturedRequest: URLRequest?
    static var lastCapturedRequestBodyData: Data? // New property for body data
    static var requestHandlingExpectation: XCTestExpectation?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Capture the request
        MockURLProtocol.lastCapturedRequest = request
        // Reset and try to capture body data from httpBody or httpBodyStream
        MockURLProtocol.lastCapturedRequestBodyData = nil
        if let body = request.httpBody {
            MockURLProtocol.lastCapturedRequestBodyData = body
        } else if let stream = request.httpBodyStream {
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            stream.open()
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read > 0 {
                    data.append(buffer, count: read)
                } else if read < 0 {
                    print("MockURLProtocol: Error reading from httpBodyStream: \(stream.streamError?.localizedDescription ?? "Unknown error")")
                    break
                } else { // read == 0, end of stream
                    break
                }
            }
            stream.close()
            buffer.deallocate()
            if !data.isEmpty {
                MockURLProtocol.lastCapturedRequestBodyData = data
            }
        }

        // --- Rest of the startLoading logic ---
        guard let client = client, let url = request.url else {
            XCTFail("Client or URL missing in MockURLProtocol")
            MockURLProtocol.requestHandlingExpectation?.fulfill()
            return
        }

        defer {
            MockURLProtocol.requestHandlingExpectation?.fulfill()
        }

        if let mockResponse = MockURLProtocol.mockResponses[url] {
            switch mockResponse {
            case .success(let (httpResponse, data)):
                client.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                if !data.isEmpty {
                    client.urlProtocol(self, didLoad: data)
                }
                client.urlProtocolDidFinishLoading(self)
            case .failure(let error):
                client.urlProtocol(self, didFailWithError: error)
            }
        } else {
            // Default 404
            let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        // No action needed
    }

    static func reset() {
        mockResponses.removeAll()
        lastCapturedRequest = nil
        lastCapturedRequestBodyData = nil // Reset the body data too
        requestHandlingExpectation = nil
    }

    // Mock setup functions remain the same
    static func mockSuccess(for url: URL, statusCode: Int = 200, data: Data = Data(), expectation: XCTestExpectation? = nil) {
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        mockResponses[url] = .success((response, data))
        requestHandlingExpectation = expectation
    }

    static func mockFailure(for url: URL, error: Error, expectation: XCTestExpectation? = nil) {
        mockResponses[url] = .failure(error)
        requestHandlingExpectation = expectation
    }
}
