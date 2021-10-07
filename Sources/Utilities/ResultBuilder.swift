import Foundation

@resultBuilder
struct ResultBuilder<T> {

    let paramForLinter = false

    static func buildBlock(_ content: T...) -> [T] {
        content
    }

    static func buildIf(_ content: T?) -> T? {
        content
    }

    static func buildEither(first: T) -> T {
        first
    }

    static func buildEither(second: T) -> T {
        second
    }

}
