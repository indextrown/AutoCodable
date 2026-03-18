//
//  AutoCodableSnakeCaseTests.swift
//  AutoCodableTests
//
//  Created by 김동현 on 3/18/26.
//

import XCTest
@testable import AutoCodable

@AutoCodable(codingKeyStyle: .snakeCase)
struct SnakePerson {
    let userName: String
    let userAge: Int
    let userProfileURL: String
}

@AutoCodable(codingKeyStyle: .snakeCase)
struct MixedKeyPerson {
    let userName: String
    
    @CodableKey(name: "custom_age")
    let userAge: Int
    
    let userProfileURL: String
}

final class AutoCodableSnakeCaseTests: XCTestCase {
    
    func test_snakeCase가_자동으로_적용된다() throws {
        let json =
        """
        {
            "user_name": "DongHyeon",
            "user_age": 27,
            "user_profile_url": "https://success.profile.jpg"
        }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(SnakePerson.self, from: json)
        
        XCTAssertEqual(person.userName, "DongHyeon")
        XCTAssertEqual(person.userAge, 27)
        XCTAssertEqual(person.userProfileURL, "https://success.profile.jpg")
    }
    
    func test_snakeCase_key가_없으면_디코딩_실패한다() {
        let json =
        """
        {
            "userName": "DongHyeon",
            "userAge": 27,
            "userProfileURL": "https://fail"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(
            try JSONDecoder().decode(SnakePerson.self, from: json)
        )
    }
    
    func test_JSON_key순서가_달라도_정상동작한다() throws {
        let json =
        """
        {
            "user_profile_url": "https://success.profile.jpg",
            "user_age": 27,
            "user_name": "DongHyeon"
        }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(SnakePerson.self, from: json)
        
        XCTAssertEqual(person.userName, "DongHyeon")
    }
    
    func test_추가필드는_무시된다() throws {
        let json =
        """
        {
            "user_name": "DongHyeon",
            "user_age": 27,
            "user_profile_url": "https://success.profile.jpg",
            "extra": "ignore"
        }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(SnakePerson.self, from: json)
        
        XCTAssertEqual(person.userName, "DongHyeon")
    }
    
    func test_타입이_다르면_디코딩_실패한다() {
        let json =
        """
        {
            "user_name": "DongHyeon",
            "user_age": "twenty seven",
            "user_profile_url": "https://fail"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(
            try JSONDecoder().decode(SnakePerson.self, from: json)
        )
    }
    
    func test_CodableKey가_snakeCase보다_우선한다() throws {
        let json =
        """
        {
            "user_name": "DongHyeon",
            "custom_age": 27,
            "user_profile_url": "https://success.profile.jpg"
        }
        """.data(using: .utf8)!
        
        let person = try JSONDecoder().decode(MixedKeyPerson.self, from: json)
        
        XCTAssertEqual(person.userName, "DongHyeon")
        XCTAssertEqual(person.userAge, 27) // 🔥 custom_key 사용됨
        XCTAssertEqual(person.userProfileURL, "https://success.profile.jpg")
    }
    
    func test_CodableKey가_있으면_snakeCase는_무시된다() {
        let json =
        """
        {
            "user_name": "DongHyeon",
            "user_age": 27, // ❌ 이건 무시되어야 함
            "user_profile_url": "https://success.profile.jpg"
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(
            try JSONDecoder().decode(MixedKeyPerson.self, from: json)
        )
    }
}
