import Moya
import Result

final class TVDBTokenRequestInterceptor: RequestInterceptor {
	private weak var tvdb: TVDB?

	init(tvdb: TVDB) {
		self.tvdb = tvdb
	}

	func intercept<T>(target: T.Type, endpoint: Endpoint, done: @escaping MoyaProvider<T>.RequestResultClosure) where T: TVDBType {
		guard let tvdb = self.tvdb else {
			done(.failure(MoyaError.requestMapping(endpoint.url)))
			return
		}

		guard let request = try? endpoint.urlRequest() else {
			done(.failure(MoyaError.requestMapping(endpoint.url)))
			return
		}

		let currentToken = tvdb.token

		if currentToken == nil {
			doLogin(target, tvdb, request, endpoint, done)
		} else {

			if tvdb.hasValidToken {
				done(.success(request))
			} else {
				refreshToken(target, tvdb, request, endpoint, done)
			}
		}
	}

	private func refreshToken<T: TVDBType>(_ target: T.Type,
										   _ tvdb: TVDB,
	                                       _ request: URLRequest,
	                                       _ endpoint: Endpoint,
	                                       _ done: @escaping MoyaProvider<T>.RequestResultClosure) {
		requestToken(tvdb, Authentication.refreshToken, request, target, done)
	}

	private func doLogin<T: TVDBType>(_ target: T.Type,
									  _ tvdb: TVDB,
	                                  _ request: URLRequest,
	                                  _ endpoint: Endpoint,
	                                  _ done: @escaping MoyaProvider<T>.RequestResultClosure) {
		requestToken(tvdb, Authentication.login(apiKey: tvdb.apiKey), request, target, done)
	}

	private func requestToken<T: TVDBType>(_ tvdb: TVDB,
	                                       _ target: Authentication,
	                                       _ request: URLRequest,
	                                       _ type: T.Type,
	                                       _ done: @escaping MoyaProvider<T>.RequestResultClosure) {
		tvdb.authentication.request(target) { result in
			switch result {
			case .success(let response):
				do {
					let json = try response.filterSuccessfulStatusAndRedirectCodes().mapJSON()

					guard let jsonObject = json as? [String: Any] else {
						done(.failure(MoyaError.jsonMapping(response)))
						return
					}

					guard let token = jsonObject["token"] as? String else {
						done(.failure(MoyaError.jsonMapping(response)))
						return
					}

					tvdb.token = token

					done(.success(request))
				} catch {
					done(.failure(MoyaError.underlying(error, response)))
				}
			case .failure(let error):
				done(.failure(error))
			}
		}
	}
}
