extension Bundle {
	static var testing: Bundle {
		let bundle = Bundle(identifier: "org.cocoapods.TVDB-Tests")!

		let path = bundle.bundlePath.appending("/../TVDBTestsResources.bundle")
		let testingBundle = Bundle(path: path)

		return testingBundle!
	}
}
