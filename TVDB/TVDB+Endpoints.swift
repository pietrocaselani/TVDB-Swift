import Moya

extension TVDB {
  public var authentication: MoyaProvider<Authentication> {
    return createProvider(forTarget: Authentication.self)
  }

  public var episodes: MoyaProvider<Episodes> {
    return createProvider(forTarget: Episodes.self)
  }
}
