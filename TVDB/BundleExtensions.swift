extension Bundle {
	static var testing: Bundle {
		let bundle = Bundle(for: TVDB.self)

		let path = bundle.bundlePath.appending("/../../../../TVDBTestsResources.bundle")
		let testingBundle = Bundle(path: path)

		return testingBundle!
	}
}
