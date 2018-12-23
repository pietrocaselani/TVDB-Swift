extension Bundle {
	static var testing: Bundle {
        let bundle = Bundle(for: TVDB.self)

		return findBundle(using: bundle.bundlePath)
	}

    private static func findBundle(using path: String) -> Bundle {
        let bundleName = "TVDBTestsResources.bundle"
        var upPath = "/.."

        var attempts = 0
        var testingBundle: Bundle?

        repeat {
            let fullPath = path.appending("\(upPath)/\(bundleName)")
            testingBundle = Bundle(path: fullPath)
            attempts += 1
            upPath = upPath.appending(upPath)
        } while testingBundle == nil && attempts <= 5

        return testingBundle!
    }
}
