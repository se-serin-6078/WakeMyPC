import Foundation

let packet = try MagicPacket.make(mac: "02:11:22:33:44:55")
precondition(packet.count == 102)
precondition(Array(packet.prefix(6)) == Array(repeating: 255, count: 6))
for index in 0..<16 {
    precondition(Array(packet[(6 + index * 6)..<(12 + index * 6)]) == [2,17,34,51,68,85])
}
let alternate = try MagicPacket.make(mac: "02-11-22-33-44-55")
precondition(alternate == packet)
for bad in ["", "00:00:00:00:00:00", "FF:FF:FF:FF:FF:FF", "02:11:22:33:44:GG", "02:11:22:33:44:5", "02::11:22:33:44:55"] {
    do { _ = try MagicPacket.make(mac: bad); fatalError("Accepted invalid MAC") } catch {}
}
for bad in ["https://example.com", "256.1.1.1", "255.255.255.255", "224.0.0.1", "127.0.0.1", "1.2.3", "01.2.3.4"] {
    do { _ = try MagicPacket.validate(ip: bad, port: "9"); fatalError("Accepted invalid IP") } catch {}
}
for bad in ["0", "65536", "abc", "-1"] {
    do { _ = try MagicPacket.validate(ip: "192.0.2.1", port: bad); fatalError("Accepted invalid port") } catch {}
}
let valid = try MagicPacket.validate(ip: " 192.0.2.1 ", port: "65535")
precondition(valid.1 == 65535)
print("Packet and input validation tests passed")
