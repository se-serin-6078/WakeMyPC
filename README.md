# Wake My PC — Windows + iPhone 시작 안내

SwiftUI 네이티브 iPhone 앱입니다. iOS 16 이상, 다크 화면, 전원 버튼, IPv4/MAC/UDP 포트 편집과 기기 내 자동 저장을 제공합니다. 102바이트 WOL 매직 패킷을 UDP 유니캐스트로 한 번 전송합니다. 계정, 서버, 분석 도구는 없습니다.

## 현재 검증 상태
소스와 GitHub Actions 워크플로를 제작했습니다. 이 Windows 환경에서는 Xcode/Swift 컴파일과 iPhone 설치를 실행하지 못했습니다. 포함된 테스트는 GitHub의 macOS에서 실행됩니다. 빌드 성공·설치 성공·실제 WOL 성공은 각각 별도로 확인해야 합니다. 앱 아이콘은 아직 포함하지 않은 최소 프로젝트입니다.

## 1. GitHub에 프로젝트 올리기
1. GitHub에서 새 저장소를 만들고 이름을 `WakeMyPC`로 정합니다. 무료 표준 macOS 실행기를 쓰려면 Public을 선택합니다. 개인정보는 소스에 넣지 마세요. Private은 계정의 Actions 무료 사용량과 과금 설정을 확인하세요.
2. 이 ZIP을 Windows에서 압축 해제합니다. GitHub Desktop을 설치하고 로그인합니다: https://desktop.github.com/
3. GitHub Desktop에서 File → Clone repository로 새 저장소를 PC에 복제합니다.
4. 압축에서 나온 WakeMyPC 폴더의 **내용 전체**를 복제된 저장소 폴더로 복사합니다. `.github` 폴더도 반드시 포함하세요. `project.yml`, `Sources`, `.github`가 저장소 최상위에 있어야 합니다.
5. GitHub Desktop에서 Commit to main → Publish branch 또는 Push origin을 누릅니다. `.github/workflows/build-ios.yml`도 변경 목록에 있는지 확인하세요.
6. GitHub 웹의 Actions → Build unsigned iOS IPA를 엽니다. 자동 실행이 없으면 Run workflow를 누릅니다. Actions가 비활성화되어 있으면 저장소에서 활성화합니다.
7. 성공한 실행 화면 하단 Artifacts → `WakeMyPC-unsigned`를 받습니다. 다운로드한 아티팩트 ZIP을 풀면 `WakeMyPC-unsigned.ipa`가 있습니다.

GitHub Secrets에 Apple 계정·비밀번호·인증서가 필요하지 않습니다. XcodeGen이 `project.yml`에서 Xcode 프로젝트를 생성하고 실제 iPhone용 Release 앱을 서명 없이 빌드합니다. 시뮬레이터 앱이 아닙니다. `xcodebuild -exportArchive`로 유료 배포 서명을 시도하지 않습니다. 결과는 `Payload/WakeMyPC.app`을 담은 IPA이며 iPhone에 직접 탭해서 설치할 수 없습니다.

## 2. Windows에서 무료 계정으로 설치하기
사용할 것은 **AltStore Classic + Windows AltServer**입니다. AltStore PAL은 이 안내의 설치 도구가 아닙니다.

1. https://altstore.io/ 및 공식 Windows 안내 https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows 에서 현재 AltServer와 요구되는 Apple 구성 요소를 설치합니다. 공식 안내는 Apple에서 직접 받은 iTunes/iCloud를 요구합니다. Microsoft Store 버전이 이미 있으면 공식 문제 해결 안내를 확인하세요.
2. iPhone을 USB 케이블로 연결하고 잠금 해제 → 이 컴퓨터 신뢰를 선택합니다. 케이블은 초기 설치용이며 별도 중계 장치는 필요하지 않습니다.
3. iTunes에서 iPhone의 Wi-Fi 동기화를 켭니다. AltServer를 실행하고 트레이 메뉴 Install AltStore → iPhone을 선택합니다.
4. 무료 Apple 계정으로 인증합니다. 비밀번호와 인증 코드는 GitHub나 이 채팅에 올리지 마세요.
5. iPhone 설정 → 일반 → VPN 및 기기 관리에서 개발자 계정을 신뢰합니다. 설정 → 개인정보 보호 및 보안 → 개발자 모드를 켜고 재시작 후 확인합니다. 표시 문구는 iOS 버전에 따라 다를 수 있습니다.
6. IPA를 iPhone의 파일 앱으로 옮깁니다. 예를 들어 iCloud Drive에 넣습니다. AltServer를 PC에서 켜 두고 iPhone을 같은 Wi-Fi에 연결합니다.
7. AltStore Classic → My Apps → +에서 IPA를 선택합니다. AltStore가 개인 개발 인증서로 다시 서명하고 AltServer를 통해 설치하도록 진행합니다. +가 보이지 않으면 파일 앱의 공유 메뉴에서 AltStore로 열기를 확인합니다.
8. Wake My PC가 열리는지 확인합니다. 이 단계가 **실기기 서명/설치 검증**입니다.

### unsigned IPA + AltStore의 의미와 한계
공식 AltStore 저장소는 개인 개발 인증서로 IPA를 재서명해서 설치하는 기능을 설명합니다. 따라서 암호화되지 않은 자체 빌드 IPA를 이 경로로 시도할 근거는 있습니다. 그러나 공식 문서가 이 프로젝트의 무서명 산출물과 모든 현재 iOS/계정 조합의 성공을 보장하는 것은 아닙니다. 여기서 실기기 설치를 확인하지 않았으므로 성공을 확정하지 않습니다. 서명 오류가 나면 오류 문구, iOS 버전, AltServer/AltStore 버전으로 원인을 확인해야 합니다. 단순히 확장자를 바꾸거나 임의 인증서를 추가하는 것으로 해결되지 않습니다.

무료 계정 앱은 보통 7일마다 재서명해야 하며 동시에 활성화 가능한 앱은 3개입니다. AltStore도 한 자리를 사용합니다. 만료 전에 AltServer를 켠 PC와 같은 Wi-Fi에서 AltStore의 Refresh All을 실행하세요. 자동 갱신에만 의존하지 마세요. 켜려는 PC가 꺼져 있으면 그 PC의 AltServer는 갱신을 도와줄 수 없습니다. **앱 서명이 유효한 동안의 WOL 전송에는 AltServer가 필요하지 않습니다.** 만료되었다면 PC를 다른 방법으로 켜고 서명을 갱신해야 합니다.

## 3. PC 깨우기 설정
- 공인 IPv4: 공유기의 외부 주소. 예시 문구의 `203.0.113.10`은 실제 주소가 아닙니다. 이번 버전은 도메인/DDNS, IPv6, URL을 받지 않습니다.
- MAC: PC 유선 LAN 어댑터 주소. Windows `ipconfig /all`에서 물리적 주소를 확인합니다. 콜론/하이픈 6쌍을 받습니다. Wi-Fi MAC과 혼동하지 마세요.
- 포트: 공유기에서 설정한 외부 **UDP** 포트. 기본 입력값은 9입니다. 공유기의 내부 전달 포트와 다를 수도 있습니다.
- 기존 앱으로 외부 WOL이 성공했다면 동일한 주소·MAC·포트부터 사용합니다. 먼저 iPhone의 Wi-Fi를 끄고 셀룰러에서 시험합니다. 집 Wi-Fi에서 공인 주소로 시험하면 공유기의 NAT loopback 미지원으로 실패할 수 있습니다.
- PC BIOS/UEFI의 WOL/PCIe wake, LAN 어댑터의 Wake on Magic Packet 및 전원 관리, 공유기 UDP 전달이 필요합니다. 완전 종료 지원은 메인보드/드라이버/빠른 시작 설정에 따라 달라집니다. 전원 공급이 끊긴 PC를 켤 수는 없습니다.
- 공유기가 꺼진 PC로 전달할 ARP 항목을 잊으면 잠깐 뒤부터 WOL이 실패할 수 있습니다. 고정 DHCP 할당만으로 해결되지 않을 수 있으며 공유기의 정적 ARP 또는 WOL 전달 지원을 확인해야 합니다. CGNAT/이중 NAT도 외부 수신을 막을 수 있습니다. 이 조건은 앱만으로 해결할 수 없습니다.
- LAN 유니캐스트 테스트는 내부 PC IP로 가능하지만, 잠든 PC에 대한 ARP가 없으면 실패할 수 있습니다. 로컬 네트워크 권한 요청이 나타나면 허용하세요.

## 전송 범위와 결과
이 앱은 단일 IPv4 주소에 UDP로 전송합니다. iOS에서 브로드캐스트/멀티캐스트는 Apple의 별도 entitlement가 필요하므로 사용하지 않습니다. 255로 끝나는 목적지와 멀티캐스트 등을 입력 검증으로 거부하며, 특이한 서브넷의 directed broadcast 주소도 사용하지 마세요. 공유기가 받은 유니캐스트를 내부 LAN에 어떻게 전달하는지는 공유기 설정에 달려 있습니다.

`전송 완료`는 운영체제가 102바이트를 받아들였다는 뜻입니다. UDP는 응답/전달 보장이 없고 PC의 실제 켜짐 상태도 검사하지 않습니다. 이후 Moonlight로 접속을 시도하여 확인하세요. WOL 패킷 자체에는 인증/암호화가 없으므로 공유기에는 필요한 UDP 포트만 설정하고 가능하면 송신 원본 제한을 사용하세요.

## 문제를 확인할 때
- 빌드 실패: Actions에서 빨간 단계 로그를 확인합니다. 실패 시 build-log 아티팩트도 확인합니다.
- 설치 실패: AltStore의 정확한 오류와 버전을 확인합니다. Apple 인증, 무료 계정 한도, 기기 신뢰/개발자 모드, PC 연결 문제는 빌드와 별개입니다.
- 전송 실패: 입력값과 네트워크/로컬 네트워크 접근 허용을 확인합니다.
- 전송 성공인데 안 켜짐: 같은 조건에서 기존 WOL 앱으로 비교하고 공유기 전달/ARP/PC 전원 설정을 확인합니다.

## 공식 참고 자료 (2026-11-13 확인)
- AltStore 코드/재서명 설명: https://github.com/altstoreio/AltStore
- Windows 설치: https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
- 갱신/앱 제한: https://faq.altstore.io/altstore-classic/your-altstore
- Apple 무료 계정 제한: https://developer.apple.com/help/account/basics/about-your-developer-account
- Apple UDP 권한: https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy
- GitHub Actions: https://github.com/features/actions
