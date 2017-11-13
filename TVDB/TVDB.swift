import Moya
import RxSwift
import Result

public class TVDB {
	let apiKey: String
	let dateProvider: DateProvider
	var lastTokenDate: Date?
	private let userDefaults: UserDefaults
	private let callbackQueue: DispatchQueue?
	private var interceptors: [RequestInterceptor]
	private var plugins: [PluginType]

	public internal(set) var token: String? {
		didSet {
			guard let validToken = token else { return }
			saveToken(validToken)
		}
	}

	public lazy var authentication: MoyaProvider<Authentication> = createProvider(forTarget: Authentication.self)
	public lazy var episodes: MoyaProvider<Episodes> = createProvider(forTarget: Episodes.self)

	public init(builder: TVDBBuilder) {
		guard let apiKey = builder.apiKey else {
			fatalError("TVDB needs an apiKey")
		}

		guard let userDefaults = builder.userDefaults else {
			fatalError("TVDB needs an userDefaults")
		}

		self.apiKey = apiKey
		self.userDefaults = userDefaults
		self.callbackQueue = builder.callbackQueue
		self.plugins = builder.plugins ?? [PluginType]()
		self.dateProvider = builder.dateProvider
		self.interceptors = builder.interceptors

		loadToken()

		interceptors.append(TVDBTokenRequestInterceptor(tvdb: self))

		plugins.append(AccessTokenPlugin(tokenClosure: self.token ?? ""))
	}

	func createProvider<T: TVDBType>(forTarget target: T.Type) -> MoyaProvider<T> {
		let endpointClosure = createEndpointClosure(for: target)
		let requestClosure = createRequestClosure(for: target)

		return MoyaProvider<T>(endpointClosure: endpointClosure,
		                       requestClosure: requestClosure,
		                       callbackQueue: callbackQueue,
		                       plugins: self.plugins)
	}

	private func createRequestClosure<T: TVDBType>(for target: T.Type) -> MoyaProvider<T>.RequestClosure {
		if target is Authentication.Type { return MoyaProvider.defaultRequestMapping }

		let requestClosure = { [unowned self] (endpoint: Endpoint<T>, done: @escaping MoyaProvider.RequestResultClosure) in
			self.interceptors.forEach {
				$0.intercept(endpoint: endpoint, done: done)
			}
		}

		return requestClosure
	}

	private func createEndpointClosure<T: TVDBType>(for target: T.Type) -> MoyaProvider<T>.EndpointClosure {
		let endpointClosure = { (target: T) -> Endpoint<T> in
			let endpoint = MoyaProvider.defaultEndpointMapping(for: target)
			let headers = [TVDB.headerContentType: TVDB.contentTypeJSON, TVDB.headerAccept: TVDB.acceptValue]
			return endpoint.adding(newHTTPHeaderFields: headers)
		}

		return endpointClosure
	}

	private func loadToken() {
		let tokenData = userDefaults.object(forKey: TVDB.accessTokenKey) as? Data
		if let tokenData = tokenData, let token = NSKeyedUnarchiver.unarchiveObject(with: tokenData) as? String {
			self.token = token

			if let date = userDefaults.object(forKey: TVDB.accessTokenDateKey) as? Date {
				self.lastTokenDate = date
			}
		}
	}

	private func saveToken(_ token: String) {
		let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
		lastTokenDate = dateProvider.now
		userDefaults.set(tokenData, forKey: TVDB.accessTokenKey)
		userDefaults.set(lastTokenDate, forKey: TVDB.accessTokenDateKey)
	}
}
