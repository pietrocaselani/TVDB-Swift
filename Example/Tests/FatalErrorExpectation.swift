import TVDBSwift
import XCTest

extension XCTestCase {
	func expectFatalError(expectedMessage: String, testcase: @escaping () -> Void) {

		// arrange
		let expectation = self.expectation(description: "expectingFatalError")
		var assertionMessage: String? = nil

		// override fatalError. This will pause forever when fatalError is called.
		FatalErrorUtil.replaceFatalError { message, _, _ in
			assertionMessage = message
			expectation.fulfill()
			unreachable()
		}

		// act, perform on separate thead because a call to fatalError pauses forever
		DispatchQueue.global(qos: .userInitiated).async(execute: testcase)

		waitForExpectations(timeout: 0.1) { _ in
			// assert
			XCTAssertEqual(assertionMessage, expectedMessage)

			// clean up
			FatalErrorUtil.restoreFatalError()
		}
	}
}
