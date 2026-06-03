import XCTest

final class AuthServiceIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TokenStore.clear()
    }

    override func tearDown() {
        TokenStore.clear()
        super.tearDown()
    }

    func testTokenStoreSavesAndRetrievesJWT() {
        let token = "test-jwt-token-placeholder-for-unit-testing-only"
        TokenStore.save(token)

        let retrieved = TokenStore.token
        XCTAssertEqual(retrieved, token, "TokenStore should retrieve the same token that was saved")
    }

    func testTokenStoreClearsToken() {
        TokenStore.save("test-jwt-token-placeholder-for-unit-testing-only")
        XCTAssertNotNil(TokenStore.token, "Token should exist before clearing")

        TokenStore.clear()
        XCTAssertNil(TokenStore.token, "Token should be nil after clearing")
    }

    func testTokenStoreOverwritesPreviousToken() {
        let firstToken = "test-jwt-token-placeholder-for-unit-testing-only"
        let secondToken = "test-jwt-token-placeholder-for-overwrite-test"

        TokenStore.save(firstToken)
        XCTAssertEqual(TokenStore.token, firstToken, "First token should be stored")

        TokenStore.save(secondToken)
        XCTAssertEqual(TokenStore.token, secondToken, "Second token should overwrite the first")
    }

    func testTokenStoreReturnsNilWhenEmpty() {
        XCTAssertNil(TokenStore.token, "TokenStore should return nil when no token has been saved")
    }

    func testSignOutClearsTokenStore() async {
        TokenStore.save("test-jwt-token-placeholder-for-unit-testing-only")
        XCTAssertNotNil(TokenStore.token, "Token should exist before sign out")

        let service = AuthService.shared
        await service.signOut()

        XCTAssertNil(TokenStore.token, "Token should be nil after sign out")
        XCTAssertFalse(service.isAuthenticated, "AuthService should not be authenticated after sign out")
    }
}
