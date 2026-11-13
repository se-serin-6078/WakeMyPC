import SwiftUI

struct PCProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var ip: String
    var mac: String
    var port: String
}

@MainActor
final class PCStore: ObservableObject {
    @Published private(set) var profiles: [PCProfile] = []
    @Published var selectedID: UUID? { didSet { defaults.set(selectedID?.uuidString, forKey: "selectedPC") } }
    @Published var storageError: String?
    private let defaults = UserDefaults.standard
    init() {
        if let data = defaults.data(forKey: "savedPCs") {
            do { profiles = try JSONDecoder().decode([PCProfile].self, from: data) }
            catch { storageError = "저장한 PC 정보를 읽지 못했습니다. 앱을 삭제하지 말고 확인해 주세요." }
        } else {
            let ip = defaults.string(forKey: "destination") ?? ""
            let mac = defaults.string(forKey: "mac") ?? ""
            if !ip.isEmpty || !mac.isEmpty {
                profiles = [PCProfile(name: "내 PC", ip: ip, mac: mac, port: defaults.string(forKey: "port") ?? "9")]
                persist()
            }
        }
        selectedID = defaults.string(forKey: "selectedPC").flatMap(UUID.init(uuidString:))
        if !profiles.contains(where: { $0.id == selectedID }) { selectedID = profiles.first?.id }
    }
    var selected: PCProfile? { profiles.first { $0.id == selectedID } }
    func save(_ profile: PCProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) { profiles[index] = profile }
        else { profiles.append(profile) }
        selectedID = profile.id
        persist()
    }
    func delete(_ profile: PCProfile) {
        profiles.removeAll { $0.id == profile.id }
        if selectedID == profile.id { selectedID = profiles.first?.id }
        persist()
    }
    private func persist() {
        do { defaults.set(try JSONEncoder().encode(profiles), forKey: "savedPCs") }
        catch { storageError = "PC 설정을 저장하지 못했습니다." }
    }
}

private enum Palette {
    static let background = Color(red: 0.95, green: 0.94, blue: 0.91)
    static let ink = Color(red: 0.22, green: 0.25, blue: 0.23)
    static let sage = Color(red: 0.36, green: 0.45, blue: 0.37)
    static let cream = Color(red: 0.85, green: 0.82, blue: 0.74)
}

@main
struct WakeMyPCApp: App {
    @StateObject private var store = PCStore()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store).preferredColorScheme(.light).tint(Palette.sage) }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: PCStore
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            WakeView(openLibrary: { tab = 1 }).tabItem { Label("깨우기", systemImage: "sun.max") }.tag(0)
            PCLibraryView().tabItem { Label("저장한 PC", systemImage: "desktopcomputer") }.tag(1)
        }
        .alert("저장 정보 확인", isPresented: Binding(get: { store.storageError != nil }, set: { if !$0 { store.storageError = nil } })) {
            Button("확인") { store.storageError = nil }
        } message: { Text(store.storageError ?? "") }
    }
}

struct WakeView: View {
    @EnvironmentObject private var store: PCStore
    let openLibrary: () -> Void
    @State private var sending = false
    @State private var signaled = false
    @State private var message = "작은 친구에게 기상 신호를 보내볼까요?"
    @State private var failed = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("잠든 PC에게, 좋은 아침.").font(.subheadline).foregroundStyle(.secondary)
                    ComputerBuddy(signaled: signaled, sending: sending).padding(.top, 24)
                    VStack(spacing: 8) {
                        Text(store.selected?.name ?? "아직 잠든 친구가 없어요").font(.title2.bold())
                        Text(message).font(.callout).foregroundStyle(failed ? Color.red : Color.secondary)
                            .multilineTextAlignment(.center).frame(minHeight: 44)
                    }
                    if let pc = store.selected {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Label("선택한 PC", systemImage: "checkmark.circle.fill"); Spacer(); Button("변경", action: openLibrary).disabled(sending) }
                            Text(pc.name).font(.headline)
                            Text("\(pc.ip) · UDP \(pc.port)").font(.subheadline.monospaced()).foregroundStyle(.secondary)
                            Text(pc.mac).font(.caption.monospaced()).foregroundStyle(.secondary)
                        }.padding(20).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))
                        Button(action: wake) {
                            HStack { if sending { ProgressView().tint(.white) } else { Image(systemName: "sun.max.fill") }; Text(sending ? "기상 신호 보내는 중…" : "깨워주기").bold() }
                                .frame(maxWidth: .infinity).padding(18)
                        }.buttonStyle(.plain).foregroundStyle(.white).background(Palette.sage, in: RoundedRectangle(cornerRadius: 20)).disabled(sending)
                    } else {
                        Button("첫 번째 PC 저장하기", action: openLibrary).buttonStyle(.borderedProminent).controlSize(.large)
                    }
                    Text("캐릭터 표정은 전송 연출입니다. 실제 PC 전원 상태는 Moonlight 등으로 확인해 주세요.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: 520).padding(24).frame(maxWidth: .infinity)
            }.background(Palette.background).navigationTitle("Wake My PC")
        }
        .onChange(of: store.selectedID) { _ in
            signaled = false; failed = false; message = "작은 친구에게 기상 신호를 보내볼까요?"
        }
    }
    @MainActor private func wake() {
        guard let pc = store.selected else { return }
        sending = true; failed = false; signaled = false
        Task {
            do {
                try await Task.detached(priority: .userInitiated) { try WakeSender.send(ip: pc.ip, mac: pc.mac, port: pc.port) }.value
                withAnimation(.easeInOut(duration: 0.35)) { signaled = true }
                message = "기상 신호를 보냈어요. 실제로 켜졌는지는 연결해서 확인해 주세요."
            } catch { failed = true; message = error.localizedDescription }
            sending = false
        }
    }
}

struct ComputerBuddy: View {
    var signaled: Bool
    var sending: Bool
    var body: some View {
        ZStack {
            Ellipse().fill(Palette.ink.opacity(0.08)).frame(width: 220, height: 28).offset(y: 111)
            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(Palette.cream).frame(width: 218, height: 166)
                        .shadow(color: Palette.ink.opacity(0.1), radius: 0, x: 0, y: 7)
                    RoundedRectangle(cornerRadius: 13).fill(Palette.ink).frame(width: 180, height: 121).offset(y: -7)
                    VStack(spacing: 13) {
                        HStack(spacing: 35) {
                            Text(signaled ? "•" : "−")
                            Text(signaled ? "•" : "−")
                        }.font(.system(size: 32, weight: .medium, design: .rounded))
                        Text(signaled ? "ᴗ" : "﹏").font(.system(size: 25, design: .rounded))
                    }.foregroundStyle(Color(red: 0.91, green: 0.93, blue: 0.78)).offset(y: -6)
                    HStack(spacing: 5) { Circle().fill(Palette.sage).frame(width: 5, height: 5); Capsule().fill(Palette.ink.opacity(0.22)).frame(width: 22, height: 4) }.offset(x: 64, y: 69)
                }
                RoundedRectangle(cornerRadius: 4).fill(Palette.cream).frame(width: 30, height: 20)
                Capsule().fill(Palette.cream).frame(width: 100, height: 11)
            }.rotationEffect(.degrees(sending ? -3 : 0))
            Text(signaled ? "✦" : "z Z").font(.system(size: 24, weight: .medium, design: .rounded)).foregroundStyle(Palette.sage).offset(x: 110, y: -100)
        }.frame(height: 250).frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore).accessibilityLabel(signaled ? "기상 신호를 받은 컴퓨터 캐릭터" : "졸고 있는 컴퓨터 캐릭터")
    }
}

struct PCLibraryView: View {
    @EnvironmentObject private var store: PCStore
    @State private var editor: PCProfile?
    @State private var deleting: PCProfile?
    var body: some View {
        NavigationStack {
            List {
                if store.profiles.isEmpty {
                    Section { Text("집 PC, 작업실 PC처럼 이름을 붙여 저장하세요. 저장 전에는 입력한 내용이 반영되지 않습니다.").foregroundStyle(.secondary) }
                }
                ForEach(store.profiles) { pc in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "desktopcomputer").foregroundStyle(Palette.sage)
                            Text(pc.name).font(.headline)
                            Spacer()
                            if store.selectedID == pc.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.sage).accessibilityLabel("선택됨") }
                        }
                        Text("\(pc.ip) · UDP \(pc.port)").font(.subheadline.monospaced()).foregroundStyle(.secondary)
                        HStack {
                            Button(store.selectedID == pc.id ? "선택됨" : "이 PC 선택") { store.selectedID = pc.id }.disabled(store.selectedID == pc.id)
                            Spacer()
                            Button("수정") { editor = pc }
                            Button("삭제", role: .destructive) { deleting = pc }
                        }.buttonStyle(.borderless)
                    }.padding(.vertical, 8)
                }
                Section { Text("설정은 이 기기에 저장됩니다. 깨우기 화면에서는 주소를 편집할 수 없습니다.").font(.footnote).foregroundStyle(.secondary) }
            }.scrollContentBackground(.hidden).background(Palette.background).navigationTitle("저장한 PC")
                .toolbar { ToolbarItem(placement: .primaryAction) { Button { editor = PCProfile(name: "", ip: "", mac: "", port: "9") } label: { Label("PC 추가", systemImage: "plus") } } }
                .sheet(item: $editor) { pc in ProfileEditor(profile: pc, existing: store.profiles.contains { $0.id == pc.id }) }
                .alert("PC를 삭제할까요?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                    Button("삭제", role: .destructive) { if let pc = deleting { store.delete(pc) }; deleting = nil }
                    Button("취소", role: .cancel) { deleting = nil }
                } message: { Text("저장한 주소가 삭제됩니다. PC 자체에는 영향을 주지 않습니다.") }
        }
    }
}

struct ProfileEditor: View {
    @EnvironmentObject private var store: PCStore
    @Environment(\.dismiss) private var dismiss
    @State var profile: PCProfile
    let existing: Bool
    @State private var errorMessage: String?
    @State private var discard = false
    private var original: PCProfile
    init(profile: PCProfile, existing: Bool) {
        _profile = State(initialValue: profile); self.original = profile; self.existing = existing
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("PC 이름") { TextField("예: 집 데스크톱", text: $profile.name) }
                Section("연결 주소") {
                    entry("IPv4 주소", text: $profile.ip, placeholder: "203.0.113.10", keyboard: .decimalPad)
                    entry("MAC 주소", text: $profile.mac, placeholder: "AA:BB:CC:DD:EE:FF", keyboard: .asciiCapable)
                    entry("외부 UDP 포트", text: $profile.port, placeholder: "9", keyboard: .numberPad)
                }
                Section { Text("저장을 눌러야 반영됩니다. 유니캐스트 IPv4만 지원하며, 실제 연결 정보는 공개 저장소에 올릴 필요가 없습니다.").font(.footnote) }
            }.navigationTitle(existing ? "PC 수정" : "PC 추가").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("취소") { if profile != original { discard = true } else { dismiss() } } }
                    ToolbarItem(placement: .confirmationAction) { Button("저장", action: save).bold() }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("완료") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } }
                }
                .interactiveDismissDisabled(profile != original)
                .alert("입력값 확인", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("확인") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
                .confirmationDialog("저장하지 않고 닫을까요?", isPresented: $discard, titleVisibility: .visible) { Button("변경 버리기", role: .destructive) { dismiss() }; Button("계속 편집", role: .cancel) {} }
        }
    }
    private func entry(_ label: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading) { Text(label).font(.caption).foregroundStyle(.secondary); TextField(placeholder, text: text).keyboardType(keyboard).textInputAutocapitalization(.never).autocorrectionDisabled() }.padding(.vertical, 4)
    }
    private func save() {
        do {
            let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { errorMessage = "PC 이름을 입력해 주세요."; return }
            let (ip, port) = try MagicPacket.validate(ip: profile.ip, port: profile.port)
            _ = try MagicPacket.make(mac: profile.mac)
            profile.name = name; profile.ip = ip; profile.port = String(port)
            profile.mac = profile.mac.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "-", with: ":").uppercased()
            store.save(profile); dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
