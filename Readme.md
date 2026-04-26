# AutoCodable

`AutoCodable`은 Swift Macro를 이용해 `Codable` 관련 보일러플레이트를 자동으로 생성하는 라이브러리입니다.

모델마다 반복해서 작성해야 하는 `CodingKeys`와 `Codable` 채택 코드를 줄이고, 필요한 경우 `@CodableKey`로 JSON key를 직접 지정할 수 있습니다.

## 목차

- [소개](#소개)
- [주요 기능](#주요-기능)
- [요구 사항](#요구-사항)
- [설치](#설치)
- [사용법](#사용법)
- [생성되는 코드](#생성되는-코드)
- [동작 규칙](#동작-규칙)
- [제한 사항](#제한-사항)
- [테스트](#테스트)

## 소개

`@AutoCodable`은 `struct`의 저장 프로퍼티를 분석해 다음 코드를 자동 생성합니다.

- `private enum CodingKeys: String, CodingKey`
- `extension Type: Codable {}`

또한 `@CodableKey(name:)`로 개별 프로퍼티의 JSON key를 바꿀 수 있고, `codingKeyStyle: .snakeCase` 옵션으로 전체 key 스타일을 변환할 수 있습니다.

## 주요 기능

- `CodingKeys` 자동 생성
- `Codable` 자동 채택
- `@CodableKey(name:)`를 이용한 JSON key 커스터마이징
- `codingKeyStyle: .snakeCase` 지원
- 저장 프로퍼티만 대상으로 동작

## 요구 사항

- Swift 5.9 이상
- Xcode 15 이상

## 설치

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/indextrown/AutoCodable.git", from: "1.0.0")
]
```

## 사용법

### 기본 사용

```swift
import AutoCodable

@AutoCodable
struct Person {
    let name: String
    let age: Int
}
```

### JSON key 직접 지정

```swift
import AutoCodable

@AutoCodable
struct Person {
    let name: String
    let age: Int

    @CodableKey(name: "user_profile_url")
    let profileURL: String
}
```

### snake_case 자동 변환

```swift
import AutoCodable

@AutoCodable(codingKeyStyle: .snakeCase)
struct User {
    let userName: String
    let userAge: Int
    let userProfileURL: String
}
```

## 생성되는 코드

### `@AutoCodable`

```swift
@AutoCodable
struct Person {
    let name: String
    let age: Int
}
```

위 코드는 아래처럼 확장됩니다.

```swift
struct Person {
    let name: String
    let age: Int

    private enum CodingKeys: String, CodingKey {
        case name
        case age
    }
}

extension Person: Codable {
}
```

### `@CodableKey(name:)`

```swift
@AutoCodable
struct Person {
    let name: String

    @CodableKey(name: "user_profile_url")
    let profileURL: String
}
```

위 코드는 아래처럼 확장됩니다.

```swift
struct Person {
    let name: String
    let profileURL: String

    private enum CodingKeys: String, CodingKey {
        case name
        case profileURL = "user_profile_url"
    }
}

extension Person: Codable {
}
```

### `codingKeyStyle: .snakeCase`

```swift
@AutoCodable(codingKeyStyle: .snakeCase)
struct User {
    let userName: String
    let userAge: Int
    let userProfileURL: String
}
```

위 코드는 아래처럼 확장됩니다.

```swift
struct User {
    let userName: String
    let userAge: Int
    let userProfileURL: String

    private enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case userAge = "user_age"
        case userProfileURL = "user_profile_url"
    }
}

extension User: Codable {
}
```

## 동작 규칙

- 매크로는 `struct`에만 적용됩니다. `class` 등 다른 타입에는 코드가 생성되지 않습니다.
- 저장 프로퍼티만 `CodingKeys`에 포함됩니다.
- 계산 프로퍼티는 제외됩니다.
- `static` 프로퍼티는 제외됩니다.
- `var a, b: Int` 같은 multi-binding 선언도 모두 포함됩니다.
- `@CodableKey(name:)`가 있으면 `snakeCase`보다 우선합니다.
- optional 프로퍼티는 JSON에 key가 없어도 정상 디코딩됩니다.

## 제한 사항

- 현재 구현은 `struct` 전용입니다.
- snake_case 변환은 라이브러리 내부 규칙으로 처리됩니다.
- `Codable`이 이미 명시적으로 채택된 경우의 문서화된 사용 예시는 아직 없습니다.

## 테스트

이 프로젝트는 `SwiftSyntaxMacrosTestSupport`를 사용해 매크로 확장 결과를 검증하고, 실제 `JSONDecoder`로 디코딩 동작도 함께 테스트합니다.

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

테스트 실행:

```bash
swift test
```
