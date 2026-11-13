import SwiftUI

@main
struct WakeMyPCApp: App {
    var body: some Scene { WindowGroup { ContentView().preferredColorScheme(.dark) } }
}

struct ContentView: View {
    @AppStorage("destination") private var ip = ""
    @AppStorage("mac") private var mac = ""
    @AppStorage("port") private var port = "9"
    @State private var sending = false
    @State private var message = "주소를 설정한 뒤 전원 버튼을 누르세요."
    @State private var failed = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    Text("WAKE MY PC").font(.caption.weight(.semibold)).tracking(4).foregroundStyle(.secondary)
                    Button(action: wake) {
                        ZStack {
                            Circle().fill(Color.cyan.opacity(0.12)).frame(width: 190, height: 190)
                            Circle().stroke(Color.cyan.opacity(0.6), lineWidth: 2).frame(width: 190, height: 190)
                            if sending { ProgressView().scaleEffect(2) }
                            else { Image(systemName: "power").font(.system(size: 72, weight: .light)).foregroundStyle(.cyan) }
                        }
                    }.disabled(sending).accessibilityLabel("PC에 WOL 패킷 보내기")
                    Text(sending ? "전송 중…" : "PC 깨우기").font(.title2.bold())
                    Text(message).font(.callout).foregroundStyle(failed ? Color.orange : Color.secondary)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("연결 설정").font(.headline)
                        field("공인 IPv4 주소", text: $ip, placeholder: "203.0.113.10", keyboard: .decimalPad)
                        field("PC의 MAC 주소", text: $mac, placeholder: "AA:BB:CC:DD:EE:FF", keyboard: .asciiCapable)
                        field("외부 UDP 포트", text: $port, placeholder: "9", keyboard: .numberPad)
                        Text("설정은 이 iPhone에 자동 저장됩니다.").font(.footnote).foregroundStyle(.secondary)
                    }.padding(20).background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 22))
                    Text("전송 완료는 PC가 켜졌다는 뜻이 아닙니다. 공유기와 PC의 WOL 설정이 필요합니다. 유니캐스트 IPv4만 지원합니다.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(24)
            }.background(Color(red: 0.035, green: 0.05, blue: 0.08)).navigationTitle("Wake My PC")
                .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("완료") { hideKeyboard() } } }
        }
    }
    private func field(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField(placeholder, text: text).keyboardType(keyboard).textInputAutocapitalization(.never)
                .autocorrectionDisabled().textFieldStyle(.roundedBorder).accessibilityLabel(label)
        }
    }
    private func hideKeyboard() { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    @MainActor private func wake() {
        hideKeyboard()
        let host = ip, hardware = mac, destinationPort = port
        sending = true; failed = false
        Task {
            do {
                try await Task.detached(priority: .userInitiated) { try WakeSender.send(ip: host, mac: hardware, port: destinationPort) }.value
                message = "매직 패킷 102바이트 전송 완료. PC 전원 상태는 확인하지 않았습니다."
            } catch { failed = true; message = error.localizedDescription }
            sending = false
        }
    }
}
