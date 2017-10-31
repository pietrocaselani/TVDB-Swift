import Moya

public protocol TVDBType: TargetType, AccessTokenAuthorizable {}

public extension TVDBType {

	public var baseURL: URL { return TVDB.baseURL }

	public var headers: [String : String]? { return nil }

	public var method: Moya.Method { return .get }

	public var authorizationType: AuthorizationType { return .bearer }

	public var sampleData: Data { return Data() }
}

func stubbedResponse(_ filename: String) -> Data {
  let resourcesPath = Bundle(for: TVDB.self).bundlePath
  let bundle = findBundleUsing(resourcesPath: resourcesPath)

	let url = bundle.url(forResource: filename, withExtension: "json")

  guard let fileURL = url, let data = try? Data(contentsOf: fileURL) else {
    return Data()
  }

  return data
}

private func findBundleUsing(resourcesPath: String) -> Bundle {
	var path = "/../"

	var bundle: Bundle? = nil
	var attempt = 0

	repeat {
		bundle = Bundle(path: resourcesPath.appending("\(path)TVDBTestsResources.bundle"))
		path.append("../")
		attempt += 1
	} while bundle == nil && attempt < 5

	return bundle!
}
