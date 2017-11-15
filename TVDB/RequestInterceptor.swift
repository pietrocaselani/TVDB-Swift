import Moya

public protocol RequestInterceptor {
	func intercept<T: TVDBType>(endpoint: Endpoint<T>, done: @escaping MoyaProvider<T>.RequestResultClosure)
}
