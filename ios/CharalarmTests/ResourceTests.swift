import XCTest
@testable import CharalarmLocal

class ResourceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetResource() throws {
        let fileUrl = Bundle.main.url(forResource: "resource", withExtension: "json", subdirectory: "Resource/jp.zunko.zundamon")!
        let data = try Data(contentsOf: fileUrl)
        let resource = try JSONDecoder().decode(Resource.self, from: data)
        XCTAssertNotNil(resource)
    }

}
