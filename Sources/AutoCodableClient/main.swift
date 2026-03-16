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

@AutoCodable
struct Person {
    let name: String
    let age: Int
    
    @CodableKey(name: "user_profile_url")
    let userProfileURL: String
}
