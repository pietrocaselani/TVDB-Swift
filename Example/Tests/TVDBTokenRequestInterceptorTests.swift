import XCTest
@testable import TVDBSwift

final class TVDBTokenRequestInterceptorTests: XCTestCase {
	private let userDefaultsMock = UserDefaults(suiteName: "TraktTestUserDefaults")!
	private var interceptor: TVDBTokenRequestInterceptor!
	private var tvdb: TVDB!

	override func setUp() {
		clearUserDefaults(userDefaultsMock)
		super.setUp()
	}

	private func clearUserDefaults(_ userDefaults: UserDefaults) {
		for (key, _) in userDefaults.dictionaryRepresentation() {
			userDefaults.removeObject(forKey: key)
		}
	}

	func testWithEmptyToken_retriveToken() {
		//Given
		let builder = TVDBBuilder {
			$0.apiKey = "my_apikey"
			$0.userDefaults = userDefaultsMock
		}

		self.tvdb = TVDBTestable(builder: builder)

		self.interceptor = TVDBTokenRequestInterceptor(tvdb: tvdb)

		let endpoint = tvdb.episodes.endpoint(.episode(id: 6040884))
		let resultExpectation = expectation(description: "expect to have a token on tvdb")

		//When
		interceptor.intercept(endpoint: endpoint) { _ in
			//Then
			resultExpectation.fulfill()
			XCTAssertNotNil(self.tvdb.token)
			XCTAssertEqual(self.tvdb.token, "cooltoken!")
		}

		wait(for: [resultExpectation], timeout: 1)
	}

	func testWithInvalidToken_refreshToken() {
		//Given
		let beginOfTime = Date(timeIntervalSince1970: 0)

		let builder = TVDBBuilder {
			$0.apiKey = "my_apikey"
			$0.userDefaults = userDefaultsMock
			$0.dateProvider = TestableDateProvider(now: beginOfTime.addingTimeInterval(60 * 60 * 24))
		}

		self.tvdb = TVDBTestable(builder: builder)
		tvdb.token = "my_token"
		tvdb.lastTokenDate = beginOfTime

		self.interceptor = TVDBTokenRequestInterceptor(tvdb: tvdb)

		let endpoint = tvdb.episodes.endpoint(.episode(id: 6040884))
		let resultExpectation = expectation(description: "expect to have a token on tvdb")

		//When
		interceptor.intercept(endpoint: endpoint) { _ in
			//Then
			resultExpectation.fulfill()
			XCTAssertNotNil(self.tvdb.token)
			XCTAssertEqual(self.tvdb.token, "cool_new_token!")
		}

		wait(for: [resultExpectation], timeout: 1)
	}

	func testWithValidToken_tokenShouldBeTheSame() {
		//Given
		let beginOfTime = Date(timeIntervalSince1970: 0)

		let builder = TVDBBuilder {
			$0.apiKey = "my_apikey"
			$0.userDefaults = userDefaultsMock
			$0.dateProvider = TestableDateProvider(now: beginOfTime.addingTimeInterval(60 * 60 * 24))
		}

		self.tvdb = TVDBTestable(builder: builder)
		tvdb.token = "my_token"

		self.interceptor = TVDBTokenRequestInterceptor(tvdb: tvdb)

		let endpoint = tvdb.episodes.endpoint(.episode(id: 6040884))
		let resultExpectation = expectation(description: "expect to have a token on tvdb")

		//When
		interceptor.intercept(endpoint: endpoint) { _ in
			//Then
			resultExpectation.fulfill()
			XCTAssertNotNil(self.tvdb.token)
			XCTAssertEqual(self.tvdb.token, "my_token")
		}

		wait(for: [resultExpectation], timeout: 1)
	}
}
