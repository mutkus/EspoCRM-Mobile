import XCTest
@testable import EspoCRMKit

final class EspoCRMKitTests: XCTestCase {
    func testRecordDecoding() throws {
        let payload = """
        {
            "id": "123",
            "_type": "Account",
            "name": "Test",
            "industry": "IT",
            "rating": 4.5,
            "active": true,
            "tags": ["a", "b"],
            "meta": { "owner": "john" }
        }
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(EspoRecord.self, from: payload)
        XCTAssertEqual(record.id, "123")
        XCTAssertEqual(record.type, "Account")
        XCTAssertEqual(record.attributes["name"], .string("Test"))
        XCTAssertEqual(record.attributes["rating"], .number(4.5))
        XCTAssertEqual(record.attributes["active"], .bool(true))
        XCTAssertEqual(record.attributes["tags"], .array([.string("a"), .string("b")]))
        XCTAssertEqual(record.attributes["meta"], .object(["owner": .string("john")]))
    }

    func testListResponseDecoding() throws {
        let payload = """
        {
            "total": 1,
            "list": [
                { "id": "1", "name": "Foo" }
            ]
        }
        """.data(using: .utf8)!

        struct Account: Decodable, Equatable {
            let id: String
            let name: String
        }

        let response = try JSONDecoder().decode(EspoListResponse<Account>.self, from: payload)
        XCTAssertEqual(response.total, 1)
        XCTAssertEqual(response.list.first?.name, "Foo")
    }
}
