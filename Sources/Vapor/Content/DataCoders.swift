import HTTP
import Foundation

/// Encodes encodable types to an HTTP body.
public protocol BodyEncoder {
    /// Serializes an encodable type to the data in an HTTP body.
    func encodeBody<T: Encodable>(from encodable: T) throws -> HTTPBody
}

/// Decodes decodable types from an HTTP body.
public protocol BodyDecoder {
    /// Parses a decodable type from the data in the HTTP body.
    func decode<T: Decodable>(_ decodable: T.Type, from body: HTTPBody) throws -> T
}

// MARK: Foundation

extension JSONEncoder: BodyEncoder {
    public func encodeBody<T>(from encodable: T) throws -> HTTPBody where T : Encodable {
        let data = try self.encode(encodable)
        return HTTPBody(data)
    }
}

extension JSONDecoder: BodyDecoder {
    public func decode<T>(_ decodable: T.Type, from body: HTTPBody) throws -> T where T : Decodable {
        guard let data = body.data else {
            throw VaporError(identifier: "streamingUnsupported", reason: "JSONDecodes doesn't support streaming bodies")
        }
        
        return try self.decode(T.self, from: data)
    }
}

// MARK: Single Value

extension BodyDecoder {
    /// Gets a single decodable value at the supplied key path from the data.
    func get<D>(at keyPath: [BasicKey], from body: HTTPBody) throws -> D where D: Decodable {
        let unwrapper = try self.decode(DecoderUnwrapper.self, from: body)
        var state = try ContainerState.keyed(unwrapper.decoder.container(keyedBy: BasicKey.self))

        var keys = Array(keyPath.reversed())
        if keys.count == 0 {
            return try unwrapper.decoder.singleValueContainer().decode(D.self)
        }

        while let key = keys.popLast() {
            switch keys.count {
            case 0:
                switch state {
                case .keyed(let keyed):
                    return try keyed.decode(D.self, forKey: key)
                case .unkeyed(var unkeyed):
                    return try unkeyed.nestedContainer(keyedBy: BasicKey.self)
                        .decode(D.self, forKey: key)
                }
            case 1...:
                let next = keys.last!
                if let index = next.intValue {
                    switch state {
                    case .keyed(let keyed):
                        var new = try keyed.nestedUnkeyedContainer(forKey: key)
                        state = try .unkeyed(new.skip(to: index))
                    case .unkeyed(var unkeyed):
                        var new = try unkeyed.nestedUnkeyedContainer()
                        state = try .unkeyed(new.skip(to: index))
                    }
                } else {
                    switch state {
                    case .keyed(let keyed):
                        state = try .keyed(keyed.nestedContainer(keyedBy: BasicKey.self, forKey: key))
                    case .unkeyed(var unkeyed):
                        state = try .keyed(unkeyed.nestedContainer(keyedBy: BasicKey.self))
                    }
                }
            default: fatalError()
            }
        }

        fatalError()
    }
}

/// Used to fetch a decoder wrapped in
/// a non-decoder class
fileprivate struct DecoderUnwrapper: Decodable {
    let decoder: Decoder
    init(from decoder: Decoder) throws {
        self.decoder = decoder
    }
}

/// All possible states a container can be in
/// while decoding a single value
fileprivate enum ContainerState {
    case keyed(KeyedDecodingContainer<BasicKey>)
    case unkeyed(UnkeyedDecodingContainer)
}

extension UnkeyedDecodingContainer {
    /// creates and throws away nested containers up
    /// to the given count.
    fileprivate mutating func skip(to count: Int) throws -> UnkeyedDecodingContainer {
        for _ in 0..<count {
            _ = try self.nestedContainer(keyedBy: BasicKey.self)
        }
        return self
    }
}
