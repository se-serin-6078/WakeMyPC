import Foundation

enum WakeError: LocalizedError {
    case invalidMAC, invalidIP, invalidPort, network(String)
    var errorDescription: String? {
        switch self {
        case .invalidMAC: return "MAC 주소를 AA:BB:CC:DD:EE:FF 형식으로 입력하세요."
        case .invalidIP: return "유니캐스트 IPv4 주소를 입력하세요. 도메인·URL·브로드캐스트는 지원하지 않습니다."
        case .invalidPort: return "포트는 1~65535 사이의 숫자여야 합니다."
        case .network(let message): return "전송 실패: \(message)"
        }
    }
}

enum MagicPacket {
    static func make(mac: String) throws -> Data {
        let raw = mac.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = raw.contains(":") ? raw.split(separator: ":", omittingEmptySubsequences: false) : raw.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 6 else { throw WakeError.invalidMAC }
        let bytes = try parts.map { part -> UInt8 in
            guard part.count == 2, part.allSatisfy({ $0.isASCII && $0.isHexDigit }), let byte = UInt8(part, radix: 16) else { throw WakeError.invalidMAC }
            return byte
        }
        guard bytes[0] & 1 == 0, bytes.contains(where: { $0 != 0 }) else { throw WakeError.invalidMAC }
        return Data(Array(repeating: UInt8(255), count: 6) + Array(repeating: bytes, count: 16).flatMap { $0 })
    }
    static func validate(ip: String, port: String) throws -> (String, UInt16) {
        let host = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { throw WakeError.invalidIP }
        let bytes = try parts.map { part -> UInt8 in
            guard !part.isEmpty, part.allSatisfy({ $0.isASCII && $0.isNumber }), let byte = UInt8(part), String(byte) == String(part) else { throw WakeError.invalidIP }
            return byte
        }
        // No broadcast socket option or restricted multicast entitlement is used.
        guard bytes[0] > 0, bytes[0] < 224, bytes[0] != 127, bytes[3] != 255 else { throw WakeError.invalidIP }
        let value = port.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.allSatisfy({ $0.isASCII && $0.isNumber }), let number = UInt16(value), number > 0 else { throw WakeError.invalidPort }
        return (host, number)
    }
}
