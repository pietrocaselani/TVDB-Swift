import Moya
import RxSwift

public class TVDB {
	let apiKey: String
	let userDefaults: UserDefaults
	var plugins = [PluginType]()

	var token: String? {
		didSet {
			updateAccessTokenPlugin(token)
		}
	}

	public init(apiKey: String, userDefaults: UserDefaults = UserDefaults.standard) {
		self.apiKey = apiKey
		self.userDefaults = userDefaults

		plugins.append(AuthenticationPlugin(tvdb: self))

		loadToken()
	}

	func createProvider<T: TVDBType>(forTarget target: T.Type) -> MoyaProvider<T> {
		let endpointClosure = createEndpointClosure(for: target)
		let requestClosure = createRequestClosure(for: target)

		return MoyaProvider<T>(endpointClosure: endpointClosure, requestClosure: requestClosure, plugins: self.plugins)
	}

	private func createRequestClosure<T: TVDBType>(for target: T.Type) -> MoyaProvider<T>.RequestClosure {
		if target is Authentication.Type { return MoyaProvider.defaultRequestMapping }

		let requestClosure = { [unowned self] (endpoint: Endpoint<T>, done: @escaping MoyaProvider.RequestResultClosure) in
			guard let request = try? endpoint.urlRequest() else {
				done(.failure(MoyaError.requestMapping(endpoint.url)))
				return
			}

			if self.token != nil {
				done(.success(request))
				return
			}

			self.authentication.request(.login, completion: { result in
				switch result {
				case .success(let response):
					do {
						let json = try response.filterSuccessfulStatusAndRedirectCodes().mapJSON()

						guard let jsonObject = json as? [String: Any] else {
							done(.failure(MoyaError.requestMapping(endpoint.url)))
							return
						}

						guard let token = jsonObject["token"] as? String else {
							done(.failure(MoyaError.requestMapping(endpoint.url)))
							return
						}

						self.token = token

						var newRequest = request
						newRequest.addValue(token, forHTTPHeaderField: "Authorization")

						done(.success(newRequest))
					} catch {
						done(.failure(MoyaError.underlying(error, response)))
					}
				case .failure(let error):
					done(.failure(error))
				}
			})
		}

		return requestClosure
	}

	private func createEndpointClosure<T: TVDBType>(for target: T.Type) -> MoyaProvider<T>.EndpointClosure {
		let endpointClosure = { (target: T) -> Endpoint<T> in
			var endpoint = MoyaProvider.defaultEndpointMapping(for: target)
			let headers = [TVDB.headerContentType: TVDB.contentTypeJSON, TVDB.headerAccept: TVDB.acceptValue]
			endpoint = endpoint.adding(newHTTPHeaderFields: headers)
			return endpoint
		}

		return endpointClosure
	}

	private func loadToken() {
		let tokenData = userDefaults.object(forKey: TVDB.accessTokenKey) as? Data
		if let tokenData = tokenData, let token = NSKeyedUnarchiver.unarchiveObject(with: tokenData) as? String {
			self.token = token
		}
	}

	private func saveToken(_ token: String) {
		let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
		userDefaults.set(tokenData, forKey: TVDB.accessTokenKey)
	}

	private func updateAccessTokenPlugin(_ token: String?) {
		if let index = self.plugins.index(where: { $0 is AccessTokenPlugin }) {
			plugins.remove(at: index)
		}

		if let token = token {
				let plugin = AccessTokenPlugin(tokenClosure: { () -> String in
				return token
			}())

			plugins.append(plugin)
			saveToken(token)
		}
	}
}
