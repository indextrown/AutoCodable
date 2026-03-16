# AutoCodable
Swift Macro를 이용해 `Codable` 코드를 자동으로 생성하는 라이브러리입니다.
모델에서 반복적으로 작성해야 하는 `CodingKeys`와 `Codable`를 자동으로 생성하여  
보일러플레이트 코드를 줄여줍니다.

--- 

## 주요 기능
- `CodingKeys` 자동 생성
- `Codable` 자동 채택
- `@CodableKey`를 이용한 Json Key 커스터마이징
- Swift Macro 기반 코드 생성

## Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/indextrown/AutoCodable.git", from: "1.0.0")
]
```

## 요구 사항
- Swift 5.9 이상
- Xcode 15 이상

## 사용법

### 예시1
```swift
// 기본 사용
@AutoCodable
struct Person {
    let name: String
    let age: Int
}

// 생성되는 코드
struct Person {
    let name: String
    let age: Int

    private enum CodingKeys: String, CodingKey {
        case name
        case age
    }
}

extension Person: Codable {}
```

### 예시2
```swift
// 기본 사용
@AutoCodable
struct Person {
    let name: String
    let age: Int

    @CodableKey(name: "user_profile_url")
    let profileURL: String
}

// 생성되는 코드
struct Person {
    let name: String
    let age: Int

    private enum CodingKeys: String, CodingKey {
        case name
        case age
        case profileURL = "user_profile_url"
    }
}
```

## 테스트
- `SwiftSyntaxMacrosTestSupport`를 사용하여 매크로 확장 결과가 예상 코드와 동일한지 검증합니다.
```swift
assertMacroExpansion(
    """
    @AutoCodable
    struct Person {
        let name: String
    }
    """,
    expandedSource:
    """
    struct Person {
        let name: String

        private enum CodingKeys: String, CodingKey {
            case name
        }
    }

    extension Person: Codable {
    }
    """
)
```