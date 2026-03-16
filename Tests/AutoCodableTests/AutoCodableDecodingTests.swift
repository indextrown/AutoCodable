//
//  AutoCodableDecodingTests.swift
//  AutoCodable
//
//  Created by 김동현 on 3/17/26.
//

import XCTest
@testable import AutoCodable

@AutoCodable
struct Person {
    let name: String
    let age: Int
    
    @CodableKey(name: "user_profile_url")
    let profileURL: String
    let address: String?
}

final class AutoCodableDecodingTests: XCTestCase {
    func test_JSON을_정상적으로_디코딩한다() throws {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": 27,
            "user_profile_url": "https://success"
        }
        """.data(using: .utf8)!
        let people = try JSONDecoder().decode(Person.self, from: json)
        XCTAssertEqual(people.name, "DongHyeon")
        XCTAssertEqual(people.age, 27)
    }
    
    func test_CodableKey_JSON키_매핑이_정상동작한다() throws {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": 27,
            "user_profile_url": "https://success.profile.jpg"
        }
        """.data(using: .utf8)!
        let people = try JSONDecoder().decode(Person.self, from: json)
        XCTAssertEqual(people.name, "DongHyeon")
        XCTAssertEqual(people.profileURL, "https://success.profile.jpg")
    }
    
    func test_JSON키가_없으면_디코딩이_실패한다() {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": 27,
        }
        """.data(using: .utf8)!
        XCTAssertThrowsError(
            try JSONDecoder().decode(Person.self, from: json)
        )
    }
    
    func test_optional_property는_없어도_디코딩된다() throws {
        let json = """
        {
            "name": "DongHyeon",
            "age": 27,
            "user_profile_url": "https://success.profile.jpg"
        }
        """.data(using: .utf8)!
        let people = try JSONDecoder().decode(Person.self, from: json)
        XCTAssertEqual(people.name, "DongHyeon")
        XCTAssertNil(people.address)
    }
    
    func test_JSON에_추가필드가_있어도_디코딩된다() throws {
        let json = """
        {
            "name": "DongHyeon",
            "age": 27,
            "user_profile_url": "https://success.profile.jpg",
            "extra": "ignore"
        }
        """.data(using: .utf8)!
        let people = try JSONDecoder().decode(Person.self, from: json)
        XCTAssertEqual(people.name, "DongHyeon")
    }
    
    func test_타입이_다르면_디코딩이_실패한다() {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": "twenty seven",
            "user_profile_url": "https://success"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(
            try JSONDecoder().decode(Person.self, from: json)
        )
    }
    
    func test_optional_property가_있으면_정상_디코딩된다() throws {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": 27,
            "user_profile_url": "https://success.profile.jpg",
            "address": "Seoul"
        }
        """.data(using: .utf8)!

        let people = try JSONDecoder().decode(Person.self, from: json)

        XCTAssertEqual(people.address, "Seoul")
    }
    
    func test_optional_property가_null이면_nil로_디코딩된다() throws {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": 27,
            "user_profile_url": "https://success.profile.jpg",
            "address": null
        }
        """.data(using: .utf8)!

        let people = try JSONDecoder().decode(Person.self, from: json)
        XCTAssertNil(people.address)
    }
    
    func test_CodableKey가_없으면_디코딩_실패한다() {
        let json =
        """
        {
            "name": "DongHyeon",
            "age": 27
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(
            try JSONDecoder().decode(Person.self, from: json)
        )
    }
    
    func test_JSON_key순서가_달라도_디코딩된다() throws {
        let json =
        """
        {
            "user_profile_url": "https://success.profile.jpg",
            "age": 27,
            "name": "DongHyeon"
        }
        """.data(using: .utf8)!

        let people = try JSONDecoder().decode(Person.self, from: json)

        XCTAssertEqual(people.name, "DongHyeon")
    }
}
