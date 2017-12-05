import Foundation
import Bits

/// A helper class that helps with parsing a packet
final class Parser {
    /// Keeps track of the current parser position
    var position: Int
    
    /// The packet which is being parsed
    var packet: Packet
    
    /// Creates a new parser
    init(packet: Packet, position: Int = 0) {
        self.packet = packet
        self.position = position
    }
    
    /// Accesses the packet's payload (helper)
    var payload: ByteBuffer {
        return packet.payload
    }
    
    /// Requires `n` amount of bytes or throws an error
    func require(_ n: Int) throws {
        guard position &+ n <= packet.payload.count else {
            throw MySQLError(.invalidPacket)
        }
    }
    
    /// Helper that reads a single byte
    func byte() throws -> UInt8 {
        try require(1)
        
        defer { position = position &+ 1 }
        
        return self.payload[position]
    }
    
    /// Reads a buffer of `length` bytes
    func buffer(length: Int) throws -> [UInt8] {
        try require(length)
        
        defer { position = position &+ length }
        
        return Array(payload[position..<position &+ length])
    }
    
    /// Reads 2 bytes into an UInt16
    func parseUInt16() throws -> UInt16 {
        try require(2)
        
        defer { position = position &+ 2 }
        
        return self.payload.baseAddress!.advanced(by: position).withMemoryRebound(to: UInt16.self, capacity: 1) { $0.pointee }
    }
    
    /// Reads 4 bytes into an UInt32
    func parseUInt32() throws -> UInt32 {
        try require(4)
        
        defer { position = position &+ 4 }
        
        return self.payload.baseAddress!.advanced(by: position).withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
    }
    
    /// Reads 8 bytes into an UInt64
    func parseUInt64() throws -> UInt64 {
        try require(8)
        
        defer { position = position &+ 8 }
        
        return self.payload.baseAddress!.advanced(by: position).withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
    }
    
    /// Parses the length encoded integer
    func parseLenEnc() throws -> UInt64 {
        guard position < self.payload.count else {
            throw MySQLError(.invalidResponse)
        }
        
        switch self.payload[position] {
        case 0xfc:
            position = position &+ 1
            
            return UInt64(try parseUInt16())
        case 0xfd:
            position = position &+ 1
            
            return UInt64(try parseUInt32())
        case 0xfe:
            position = position &+ 1
            
            return try parseUInt64()
        case 0xff:
            throw MySQLError(packet: packet)
        default:
            defer { position = position &+ 1 }
            return numericCast(self.payload[position])
        }
    }
    
    /// Parses length encoded Data
    func parseLenEncData() throws -> Data {
        let length = try skipLenEnc()
        
        return Data(self.payload[position &- length..<position &+ length])
    }
    
    /// Parses length encoded Data
    func parseLenEncBytes() throws -> ByteBuffer {
        let length = try skipLenEnc()
        
        return ByteBuffer(start: self.payload.baseAddress?.advanced(by: position &- length), count: length)
    }
    
    /// Skips length encoded data/strings
    @discardableResult
    func skipLenEnc() throws -> Int {
        let length = Int(try parseLenEnc())
        
        guard position &+ length <= self.payload.count else {
            throw MySQLError(.invalidResponse)
        }
        
        defer { position = position &+ length }
        
        return length
    }
    
    /// Parses a length encoded string
    func parseLenEncString() throws -> String {
        let length = try skipLenEnc()
        
        guard length > 0 else {
            return ""
        }
        
        let data = Data(bytes: self.payload.baseAddress!.advanced(by: position &- length), count: length)
        let result = String(data: data, encoding: .utf8)
        
        return result ?? ""
    }
}
