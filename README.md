# HiCardi Auto BLE DFU App

BLE 기기용 자동 DFU(Device Firmware Update) Flutter 애플리케이션입니다. HiCardi 시리즈 기기의 펌웨어 업데이트를 효율적으로 관리할 수 있습니다.

## 주요 기능

- **BLE 기기 스캔**: HiCardi 시리즈 기기 자동 필터링
- **다중 기기 DFU**: 여러 기기 동시 펌웨어 업데이트
- **필터링 시스템**: 모델별, 시리얼 번호 범위별 기기 필터링
- **진행률 모니터링**: 실시간 DFU 진행 상태 확인
- **히스토리 관리**: DFU 성공/실패 기록 관리

## 아키텍처

이 프로젝트는 Clean Architecture 원칙을 따라 구성되었습니다:

```
lib/
├── main.dart                           # 앱 진입점
├── core/                              # 핵심 유틸리티
│   ├── constants/                     # 상수 정의
│   │   ├── app_constants.dart         # 앱 전반 상수
│   │   └── dfu_constants.dart         # DFU 관련 상수
│   └── utils/                         # 유틸리티 함수
│       ├── date_formatter.dart        # 날짜 포매팅
│       └── serial_validator.dart      # 시리얼 번호 검증
├── data/                              # 데이터 계층
│   ├── models/                        # 데이터 모델
│   │   ├── device_dfu_progress.dart   # DFU 진행률 모델
│   │   └── dfu_history_item.dart      # DFU 히스토리 모델
│   ├── repositories/                  # 데이터 저장소
│   │   └── preferences_repository.dart # SharedPreferences 관리
│   └── services/                      # 서비스 레이어
│       ├── ble_service.dart           # BLE 스캔/필터링 서비스
│       ├── dfu_service.dart           # DFU 실행 서비스
│       └── permission_service.dart     # 권한 관리 서비스
├── presentation/                      # 프레젠테이션 계층
│   ├── providers/                     # 상태 관리 (Provider)
│   │   ├── ble_provider.dart          # BLE 상태 관리
│   │   └── dfu_provider.dart          # DFU 상태 관리
│   └── widgets/                       # 재사용 가능한 위젯
│       ├── device_list_widget.dart    # 기기 목록 위젯
│       ├── filter_widget.dart         # 필터링 위젯
│       ├── firmware_selector_widget.dart # 펌웨어 선택 위젯
│       └── progress_indicator_widget.dart # 진행률 표시 위젯
└── screens/                          # 화면 정의
    ├── dfu_screen.dart               # 메인 DFU 화면
    ├── dfu_history_screen.dart       # DFU 히스토리 화면
    └── dfu_progress_screen.dart      # DFU 진행률 화면
```

## 의존성

### 주요 패키지

- **flutter_blue_plus**: BLE 통신
- **nordic_dfu**: Nordic DFU 프로토콜 구현
- **provider**: 상태 관리
- **file_picker**: 파일 선택
- **permission_handler**: 권한 관리
- **shared_preferences**: 로컬 저장소

### 개발 도구

- **flutter_lints**: 코드 품질 도구

## 설치 및 실행

### 사전 요구사항

- Flutter 3.8.1 이상
- Dart 3.0 이상
- Android/iOS 개발 환경

### 설치

```bash
# 저장소 클론
git clone <repository-url>
cd HiCardi-Auto-BLE_DFU-App

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 사용법

### 1. 기기 스캔
- 앱바의 검색 아이콘을 터치하여 BLE 기기 스캔 시작
- HiCardi 시리즈 기기가 자동으로 필터링되어 표시

### 2. 기기 필터링
- **모델 필터**: 전체, HiCardi-, HiCardi-A/C/D/E/M/N 선택 가능
- **시리얼 범위**: 시작/끝 번호로 기기 범위 지정

### 3. 펌웨어 선택
- 상단의 펌웨어 선택 영역에서 ZIP 파일 선택
- 선택된 파일은 자동으로 저장되어 다음 실행 시 유지

### 4. DFU 실행
- 기기 선택 후 하단의 "DFU 업데이트 시작" 버튼 터치
- 진행률 화면에서 실시간 상태 확인 가능
- 다중 기기 선택 시 순차적으로 진행

### 5. 히스토리 확인
- 앱바의 히스토리 아이콘에서 이전 DFU 기록 확인
- 성공/실패 상태 및 오류 메시지 확인 가능

## Clean Code 원칙 적용

### 1. 단일 책임 원칙 (SRP)
- 각 클래스와 함수는 하나의 책임만 가짐
- BLE 스캔, DFU 실행, 히스토리 관리를 별도 서비스로 분리

### 2. 의존성 역전 원칙 (DIP)
- 고수준 모듈이 저수준 모듈에 의존하지 않도록 설계
- Repository 패턴으로 데이터 접근 추상화

### 3. 개방-폐쇄 원칙 (OCP)
- 확장에는 열려있고 수정에는 닫혀있도록 설계
- 새로운 기기 필터나 DFU 타입 추가가 용이

### 4. 코드 품질
- **상수 관리**: 매직 넘버 제거, 상수 파일로 중앙 관리
- **유틸리티 함수**: 재사용 가능한 함수들을 별도 파일로 분리
- **위젯 분리**: 재사용 가능한 UI 컴포넌트 모듈화
- **에러 처리**: 적절한 예외 처리 및 사용자 피드백

## 특징

### 확장성
- 새로운 기기 모델 추가가 용이한 구조
- 다양한 DFU 프로토콜 지원 가능

### 유지보수성
- 계층별 관심사 분리로 코드 수정 영향 범위 최소화
- 단위 테스트 작성이 용이한 구조

### 성능
- 효율적인 BLE 스캔 및 UI 업데이트
- 메모리 누수 방지를 위한 리소스 정리

## 라이센스

이 프로젝트는 MIT 라이센스 하에 배포됩니다.

## 기여

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 지원

문제 발생 시 GitHub Issues를 통해 문의해주세요.