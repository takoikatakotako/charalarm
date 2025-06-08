import XCTest
@testable import CharalarmLocal

class ResourceTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetResource() {

        let fileUrl = Bundle.main.url(forResource: "resource", withExtension: "json", subdirectory: "Resource/jp.zunko.zundamon")!
        let data = try! Data(contentsOf: fileUrl)

        do {
            let resource: Resource = try JSONDecoder().decode(Resource.self, from: data)
        } catch {
            print(error)
        }

//        if let resource: Resource = try? JSONDecoder().decode(Resource.self, from: data) {
//
//        } else {
//            XCTFail()
//        }
    }

}
