import Moya
import RxSwift
import Result

public class TVDB {
	let apiKey: String
	let dateProvider: DateProvider
	internal private(set) var lastTokenDate: Date?
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

	public var hasValidToken: Bool {
		guard let tokenDate = lastTokenDate else { return false }

		let now = dateProvider.now.timeIntervalSince1970
		let lastTokenTimeInterval = tokenDate.timeIntervalSince1970
		let diff = now - lastTokenTimeInterval

		return diff < 86400
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
		if target is Authentication.Type { return MoyaProvider<T>.defaultRequestMapping }

		let requestClosure = { [unowned self] (endpoint: Endpoint, done: @escaping MoyaProvider.RequestResultClosure) in
			self.interceptors.forEach {
				$0.intercept(target: target, endpoint: endpoint, done: done)
			}
		}

		return requestClosure
	}

	private func createEndpointClosure<T: TVDBType>(for target: T.Type) -> MoyaProvider<T>.EndpointClosure {
		let endpointClosure = { (target: T) -> Endpoint in
			let endpoint = MoyaProvider.defaultEndpointMapping(for: target)
			let headers = [TVDB.headerContentType: TVDB.contentTypeJSON, TVDB.headerAccept: TVDB.acceptValue]
			return endpoint.adding(newHTTPHeaderFields: headers)
		}

		return endpointClosure
	}

	private func loadToken() {
		guard let tokenData = userDefaults.object(forKey: TVDB.accessTokenKey) as? Data else { return }

		guard let tokenDate = userDefaults.object(forKey: TVDB.accessTokenDateKey) as? Date else { return }

		guard let token = NSKeyedUnarchiver.unarchiveObject(with: tokenData) as? String else { return }

		self.token = token
		self.lastTokenDate = tokenDate
	}

	private func saveToken(_ token: String) {
		let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
		lastTokenDate = dateProvider.now
		userDefaults.set(tokenData, forKey: TVDB.accessTokenKey)
		userDefaults.set(lastTokenDate, forKey: TVDB.accessTokenDateKey)
	}
}
