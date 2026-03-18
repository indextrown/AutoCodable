import AutoCodable

/**
struct Person {
    let name: String
    let age: Int
    let userPofileURL: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case age
        case userPofileURL = "user_profile_url"
    }
}
*/

/*
@AutoCodable
struct Person {
    let name: String
    let age: Int
    
    @CodableKey(name: "user_profile_url")
    let userProfileURL: String
}
*/

import Foundation

@AutoCodable(codingKeyStyle: .snakeCase)
struct User {
    let userName: String
    let userAge: Int
    let userProfileURL: String
}

func main() {
    let json = """
    {
        "user_name": "DongHyeon",
        "user_age": 27,
        "user_profile_url": "https://success.profile.jpg"
    }
    """.data(using: .utf8)!

    do {
        let user = try JSONDecoder().decode(User.self, from: json)
        
        print("✅ 디코딩 성공")
        print("name:", user.userName)
        print("age:", user.userAge)
        print("url:", user.userProfileURL)
        
    } catch {
        print("❌ 디코딩 실패:", error)
    }
}

main()

