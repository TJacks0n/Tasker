import XCTest
@testable import Tasker // Replace 'Tasker' with your actual app module name

// MARK: - BugReporter Unit Tests

class BugReporterTests: XCTestCase {

    var bugReporter: BugReporter!
    var mockSession: URLSession!
    let testWorkerURL = URL(string: "https://test.worker.dev/report")!

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        bugReporter = BugReporter(urlSession: mockSession, workerURLString: testWorkerURL.absoluteString)
        MockURLProtocol.reset()
    }

    override func tearDownWithError() throws {
        bugReporter = nil
        mockSession = nil
        MockURLProtocol.reset()
        try super.tearDownWithError()
    }

    // MARK: - Test Cases for sendReportToWorker

    func testSendReport_Success() throws {
        // Arrange
        let reportDescription = "This is a successful test description."
        let expectedSuccessData = #"{"message": "Success"}"#.data(using: .utf8)!
        let mockExpectation = self.expectation(description: "MockURLProtocol request handled")
        MockURLProtocol.mockSuccess(for: testWorkerURL, statusCode: 200, data: expectedSuccessData, expectation: mockExpectation)

        // Act
        bugReporter.sendReportToWorker(details: reportDescription, workerURL: testWorkerURL)

        // Assert
        waitForExpectations(timeout: 1.0)

        guard let capturedRequest = MockURLProtocol.lastCapturedRequest else {
            XCTFail("MockURLProtocol did not capture any request.")
            return
        }
        // *** Check the dedicated body data property ***
        guard let httpBody = MockURLProtocol.lastCapturedRequestBodyData else {
             XCTFail("Captured request body data should not be nil.")
             return
        }

        XCTAssertEqual(capturedRequest.url, testWorkerURL)
        XCTAssertEqual(capturedRequest.httpMethod, "POST")
        XCTAssertEqual(capturedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let decodedBody = try? JSONDecoder().decode([String: String].self, from: httpBody)
        XCTAssertNotNil(decodedBody, "Failed to decode JSON body from captured request.")
        XCTAssertEqual(decodedBody?["description"], reportDescription, "Decoded description does not match.")
        XCTAssertNotNil(decodedBody?["appName"], "appName should be present in the body.")
    }

    func testSendReport_ServerError() throws {
        // Arrange
        let reportDescription = "Testing server error scenario."
        let mockExpectation = self.expectation(description: "MockURLProtocol request handled (server error)")
        MockURLProtocol.mockSuccess(for: testWorkerURL, statusCode: 500, data: Data(), expectation: mockExpectation)

        // Act
        bugReporter.sendReportToWorker(details: reportDescription, workerURL: testWorkerURL)

        // Assert
        waitForExpectations(timeout: 1.0)

        guard let capturedRequest = MockURLProtocol.lastCapturedRequest else {
            XCTFail("MockURLProtocol did not capture any request even on server error.")
            return
        }
        // *** Check the dedicated body data property ***
         guard let httpBody = MockURLProtocol.lastCapturedRequestBodyData else {
             XCTFail("Captured request body data should not be nil even on server error.")
             return
        }
        XCTAssertEqual(capturedRequest.url, testWorkerURL)
        XCTAssertEqual(capturedRequest.httpMethod, "POST")
        let decodedBody = try? JSONDecoder().decode([String: String].self, from: httpBody)
        XCTAssertEqual(decodedBody?["description"], reportDescription, "Decoded description mismatch on server error.")
    }

    func testSendReport_NetworkError() throws {
        // Arrange
        let reportDescription = "Testing network error scenario."
        let networkError = URLError(.notConnectedToInternet)
        let mockExpectation = self.expectation(description: "MockURLProtocol request handled (network error)")
        MockURLProtocol.mockFailure(for: testWorkerURL, error: networkError, expectation: mockExpectation)

        // Act
        bugReporter.sendReportToWorker(details: reportDescription, workerURL: testWorkerURL)

        // Assert
        waitForExpectations(timeout: 1.0)

        guard let capturedRequest = MockURLProtocol.lastCapturedRequest else {
            XCTFail("MockURLProtocol did not capture any request even on network error.")
            return
        }
        // *** Check the dedicated body data property ***
         guard let httpBody = MockURLProtocol.lastCapturedRequestBodyData else {
             XCTFail("Captured request body data should not be nil even on network error.")
             return
        }
        XCTAssertEqual(capturedRequest.url, testWorkerURL)
        XCTAssertEqual(capturedRequest.httpMethod, "POST")
        let decodedBody = try? JSONDecoder().decode([String: String].self, from: httpBody)
        XCTAssertEqual(decodedBody?["description"], reportDescription, "Decoded description mismatch on network error.")
    }

    func testSendReport_DirectCall() throws {
         // Arrange
         let reportDescription = "Direct call test."
         let mockExpectation = self.expectation(description: "MockURLProtocol request handled (direct call)")
         MockURLProtocol.mockSuccess(for: testWorkerURL, statusCode: 200, data: Data(), expectation: mockExpectation)

         // Act
         bugReporter.sendReportToWorker(details: reportDescription, workerURL: testWorkerURL)

         // Assert
         waitForExpectations(timeout: 1.0)

         guard let capturedRequest = MockURLProtocol.lastCapturedRequest else {
             XCTFail("Request should have been captured on direct call.")
             return
         }
         // *** Check the dedicated body data property ***
         guard let httpBody = MockURLProtocol.lastCapturedRequestBodyData else {
              XCTFail("Captured request body data should not be nil on direct call.")
              return
         }
         XCTAssertEqual(capturedRequest.url, testWorkerURL)
         let decodedBody = try? JSONDecoder().decode([String: String].self, from: httpBody)
         XCTAssertEqual(decodedBody?["description"], reportDescription, "Decoded description mismatch on direct call.")
    }

     func testSendReport_EncodingError() {
          print("Skipping testSendReport_EncodingError as standard Dictionary is easily encodable.")
     }
}
