import Async

public final class Lowercase: Leaf.Tag {
    public init() {}
    public func render(parsed: ParsedTag, context: inout LeafData, renderer: LeafRenderer) throws -> Future<LeafData?> {
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string?.lowercased() ?? ""

        let promise = Promise(LeafData?.self)
        promise.complete(.string(string))
        return promise.future
    }
}
