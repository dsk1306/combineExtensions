import Foundation

@resultBuilder
public struct ResultBuilder<T> {

    let paramForLinter = false

    public static func buildBlock(_ content: T...) -> [T] {
        content
    }

    public static func buildIf(_ content: T?) -> T? {
        content
    }

    public static func buildEither(first: T) -> T {
        first
    }

    public static func buildEither(second: T) -> T {
        second
    }

}
