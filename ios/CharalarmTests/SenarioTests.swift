import XCTest
@testable import CharalarmLocal

class SenarioTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSenario() async throws {
        // Auth Info
        let userID = UUID()
        let authToken = UUID()

        let otherRepository = OtherRepository()
        let isMaintenance = try await otherRepository.fetchMaintenance()
        XCTAssertEqual(isMaintenance, false, "Expected is not maintenance")

        let requireVersion = try await otherRepository.fetchRequireVersion()
        XCTAssertEqual(requireVersion, "3.0.0")

        // ユーザー登録
        let userRepository = UserRepository()
        let userSignUpRequest = UserSignUpRequest(userID: userID.uuidString, authToken: authToken.uuidString, platform: "iOS")
        try await userRepository.signup(request: userSignUpRequest)

        // プッシュトークン追加
        // TODO: 色々調べる

        // ユーザー退会
        try await userRepository.withdraw(userID: userID.uuidString, authToken: authToken.uuidString)
    }
}
