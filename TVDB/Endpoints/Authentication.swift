import Moya

public enum Authentication {
  case login
}

extension Authentication: TVDBType {

  public var path: String {
    return "login"
  }

	public var authorizationType: AuthorizationType {
		return .none
	}

  public var method: Moya.Method { return .post }

	public var task: Task {
		return .requestPlain
	}

  public var sampleData: Data {
    return stubbedResponse("tvdb_login")
  }
}
