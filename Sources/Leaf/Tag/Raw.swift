import Async

public final class Raw: Tag {
    public init() { }

    public func render(parsed: ParsedTag, context: inout LeafData, renderer: LeafRenderer) throws -> Future<LeafData?> {
        try parsed.requireNoBody()
        try parsed.requireParameterCount(1)
        let string = parsed.parameters[0].string ?? ""
        let promise = Promise(LeafData?.self)
        promise.complete(.string(string))
        return promise.future
    }
}


