# YouTube 트렌드 데이터 수집 서비스

Rails 8.0 기반 YouTube 트렌드 데이터 수집 및 분석 서비스

## 🚀 Railway 배포 가이드

### 1. GitHub에 코드 업로드
```bash
git add .
git commit -m "Ready for Railway deployment"
git push origin main
```

### 2. Railway 배포
1. [Railway](https://railway.app)에 접속 후 GitHub 계정으로 로그인
2. "New Project" → "Deploy from GitHub repo" 선택
3. 이 저장소 선택
4. SQLite 데이터베이스가 자동으로 설정됩니다

### 3. 환경변수 설정
Railway 대시보드에서 다음 환경변수를 설정하세요:

```
YOUTUBE_API_KEY=당신의_YouTube_API_키
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
```

### 4. 배포 완료
- 자동으로 빌드 및 배포가 진행됩니다
- 배포 완료 후 Railway에서 제공하는 URL로 접속 가능

## 📋 주요 기능

- **YouTube 트렌드 데이터 수집**: 11개국 지역별 트렌드 수집 (한국, 미국, 일본, 영국, 독일, 프랑스, 베트남, 인도네시아, 인도, 브라질, 러시아)
- **관리자 대시보드**: 데이터 수집 관리, 사용자 관리
- **사용자 인증**: Rails 내장 인증 시스템
- **검색 기능**: YouTube 동영상 검색 및 필터링
- **반응형 UI**: Bootstrap 5 기반 모던 디자인

## 🛠️ 로컬 개발 환경 설정

### 1. 설치
```bash
bundle install
rails db:setup
```

### 2. 환경변수 설정
`.env` 파일을 생성하고 YouTube API 키를 설정하세요:
```
YOUTUBE_API_KEY=your_api_key_here
```

### 3. 서버 실행
```bash
rails server
```

## 📊 기술 스택

- **Backend**: Ruby on Rails 8.0
- **Database**: SQLite (개발/프로덕션 - Rails 8.0 production-ready)
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSocket**: Solid Cable
- **Frontend**: Bootstrap 5, Stimulus, Turbo
- **Authentication**: Rails built-in (has_secure_password)

## 🔧 관리자 기능

- 사용자 관리 (권한 변경, 계정 상태 관리)
- YouTube 데이터 수집 제어
- 데이터베이스 관리 도구
- 시스템 모니터링

## 📈 지원 지역

🇰🇷 한국, 🇺🇸 미국, 🇯🇵 일본, 🇬🇧 영국, 🇩🇪 독일, 🇫🇷 프랑스, 🇻🇳 베트남, 🇮🇩 인도네시아

---

Built with ❤️ using Rails 8.0
