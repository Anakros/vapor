//
//public struct StringKey: CodingKey {
//    public var stringValue: String
//    public var intValue: Int? {
//        return Int(stringValue)
//    }
//
//    public init?(stringValue: String) {
//        self.stringValue = stringValue
//    }
//
//    public init?(intValue: Int) {
//        stringValue = intValue.description
//    }
//}


//import Async
//
//internal struct LeafDataContainer<K: CodingKey>:
//    KeyedEncodingContainerProtocol,
//    UnkeyedEncodingContainer,
//    SingleValueEncodingContainer,
//    FutureEncoder
//{
//    typealias Key = K
//
//    var count: Int
//
//    var partialData: PartialLeafData
//    var codingPath: [CodingKey]
//
//    public init(encoder: LeafDataEncoder) {
//        self.partialData = encoder.partialData
//        self.codingPath = encoder.codingPath
//        self.count = 0
//    }
//
//    mutating func encodeNil() throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func nestedContainer<NestedKey: CodingKey>(
//        keyedBy keyType: NestedKey.Type
//    ) -> KeyedEncodingContainer<NestedKey> {
//        fatalError("unimplemented")
//    }
//
//    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
//        fatalError("unimplemented")
//    }
//
//    mutating func superEncoder() -> Encoder {
//        return LeafDataEncoder(
//            partialData: partialData,
//            codingPath: codingPath
//        )
//    }
//
//    mutating func encodeNil(forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func nestedContainer<NestedKey: CodingKey>(
//        keyedBy keyType: NestedKey.Type, forKey key: K
//    ) -> KeyedEncodingContainer<NestedKey> {
//        fatalError("unimplemented")
//    }
//
//    mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
//        fatalError("unimplemented")
//    }
//
//    mutating func superEncoder(forKey key: K) -> Encoder {
//        return LeafDataEncoder(
//            partialData: partialData,
//            codingPath: codingPath + [key]
//        )
//    }
//
//    mutating func encode(_ value: Bool) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int8) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int16) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int32) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int64) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt8) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt16) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt32) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt64) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Float) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Double) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: String) throws {
//        set(.string(value))
//    }
//
//    mutating func encode<T: Encodable>(_ value: T) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Bool, forKey key: K) throws {
//        set(.bool(value), forKey: key)
//    }
//
//    mutating func encode(_ value: Int, forKey key: K) throws {
//        set(.int(value), forKey: key)
//    }
//
//    mutating func encode(_ value: Int8, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int16, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int32, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Int64, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt8, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt16, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt32, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: UInt64, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Float, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//    mutating func encode(_ value: Double, forKey key: K) throws {
//        fatalError("unimplemented")
//    }
//
//
//    mutating func encode<E>(_ future: Future<E>) throws {
//        let promise = Promise(LeafData.self)
//
//        future.do { item in
//            if let encodable = item as? Encodable {
//                let encoder = LeafDataEncoder()
//                try! encodable.encode(to: encoder)
//                promise.complete(encoder.context)
//            } else {
//                promise.fail("could not encode")
//            }
//        }.catch { error in
//            promise.fail(error)
//        }
//
//        set(.future(promise.future))
//    }
//
//    mutating func encode(_ value: String, forKey key: K) throws {
//        set(.string(value), forKey: key)
//    }
//
//    mutating func encode<T: Encodable>(_ value: T, forKey key: K) throws {
//        let encoder = LeafDataEncoder(partialData: partialData, codingPath: codingPath + [key])
//        try value.encode(to: encoder)
//    }
//
//    mutating func set(_ context: inout LeafData, to value: LeafData?, at path: [CodingKey]) {
//        var child: LeafData?
//        switch path.count {
//        case 1:
//            child = value
//        case 2...:
//            child = context.dictionary?[path[0].stringValue] ?? LeafData.dictionary([:])
//            set(&child!, to: value, at: Array(path[1...]))
//        default: return
//        }
//
//        if case .dictionary(var dict) = context {
//            dict[path[0].stringValue] = child
//            context = .dictionary(dict)
//        } else if let child = child {
//            context = .dictionary([
//                path[0].stringValue: child
//            ])
//        }
//    }
//
//    /// Returns the value, if one at from the given path.
//    public func get(_ context: LeafData, at path: [CodingKey]) -> LeafData? {
//        var child = context
//
//        for seg in path {
//            guard let c = child.dictionary?[seg.stringValue] else {
//                return nil
//            }
//            child = c
//        }
//
//        return child
//    }
//
//    mutating func set(_ value: LeafData) {
//        set(&partialData.context, to: value, at: codingPath)
//    }
//
//    mutating func set(_ value: LeafData, forKey key: K) {
//        set(&partialData.context, to: value, at: codingPath + [key])
//    }
//}

