// The Swift Programming Language
// https://docs.swift.org/swift-book

/**
 @attached(member)
 - `타입 {} 내부에` 코드를 생성 enum CodingKeys-
 
 @attached(extension)
 - `타입에 extension Type {} 셍성`
 
 @attached(peer)
 - `같은 레벨에 새로운 선언 생성`
 
 @attached(memberAttribute)
 - `타입 내부 멤버에 attribute 추가`
 
 @attached(accessor)
 - `property의 getter / setter / observer 생성`
 
 @attached(conformance
 - `타입에 protocol 채택 추가`
 
 #externalMacro
 - 이 매크로 구현이 다른 모듈에 있다는 의미
 - 실제 구현: AutoCodableMacros/AutoCodableMacro
 */


public enum CodingKeyStyle: String {
    case useDefault
    case snakeCase
}

/**
 @AutoCodable
 struct Person {
    let name: String
    let age: Int
    
    @CodableKey(name: "user_profile_url")
    let userProfileURL: String
 }
 */
// 이 macro는 member를 생성하는데 그 이름은 CodingKeys이다
@attached(member, names: named(CodingKeys))
@attached(extension, conformances: Codable)
public macro AutoCodable(
    codingKeyStyle: CodingKeyStyle = .useDefault
) = #externalMacro(
    module: "AutoCodableMacros",
    type: "AutoCodableMacro"
)

/**
 CodableKey
 - property의 CodingKey 문자열을 변경할 때 사용
 @CodableKey(name: "user_profile_url")
 let userProfileURL: String
 */
@attached(peer)
public macro CodableKey(name: String) = #externalMacro(
    module: "AutoCodableMacros",
    type: "CodableKeyMacro"
)

/**
 @AutoCodable
 struct Person {

     let name: String
     let age: Int

     @CodableKey(name: "user_profile_url")
     let userProfileURL: String
 }
 
 struct Person {
     let name: String
     let age: Int
     let userProfileURL: String

     enum CodingKeys: String, CodingKey {
         case name
         case age
         case userProfileURL = "user_profile_url"
     }
 }

 extension Person: Codable {}
 */

//@AutoCodable(codingKeyStyle: .snakeCase)
//struct User {
//  let firstName: String
//  let lastLogin: Date
//}
//
//struct User {
//  let firstName: String
//  let lastLogin: Date
//  
//  private enum CodingKeys: String, CodingKey {
//    case firstName = "first_name"
//    case lastLogin = "last_login"
//  }
//}
//
//extension User: Codable {
//}
