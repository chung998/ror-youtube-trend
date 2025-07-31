# frozen_string_literal: true

# YouTube 지역 코드 중앙 관리 모듈
module YoutubeRegions
  extend ActiveSupport::Concern

  # 주요 지원 지역 (트렌드 수집용)
  PRIMARY_REGIONS = {
    'KR' => { name: '한국', emoji: '🇰🇷', language: 'ko', color: 'primary' },
    'US' => { name: '미국', emoji: '🇺🇸', language: 'en', color: 'info' },
    'JP' => { name: '일본', emoji: '🇯🇵', language: 'ja', color: 'danger' },
    'GB' => { name: '영국', emoji: '🇬🇧', language: 'en', color: 'success' },
    'DE' => { name: '독일', emoji: '🇩🇪', language: 'de', color: 'warning' },
    'FR' => { name: '프랑스', emoji: '🇫🇷', language: 'fr', color: 'secondary' },
    'VN' => { name: '베트남', emoji: '🇻🇳', language: 'vi', color: 'dark' },
    'ID' => { name: '인도네시아', emoji: '🇮🇩', language: 'id', color: 'info' },
    'IN' => { name: '인도', emoji: '🇮🇳', language: 'hi', color: 'success' },
    'BR' => { name: '브라질', emoji: '🇧🇷', language: 'pt', color: 'warning' },
    'RU' => { name: '러시아', emoji: '🇷🇺', language: 'ru', color: 'danger' }
  }.freeze

  # 추가 검색용 지역
  EXTENDED_REGIONS = {
    'CA' => { name: '캐나다', emoji: '🇨🇦', language: 'en', color: 'primary' },
    'AU' => { name: '호주', emoji: '🇦🇺', language: 'en', color: 'warning' },
    'MX' => { name: '멕시코', emoji: '🇲🇽', language: 'es', color: 'danger' }
  }.freeze

  # 전체 지역 (주요 + 확장)
  ALL_REGIONS = PRIMARY_REGIONS.merge(EXTENDED_REGIONS).freeze

  # 기본 지역 코드
  DEFAULT_REGION = 'KR'

  class << self
    # 주요 지역 코드 목록
    def primary_codes
      PRIMARY_REGIONS.keys
    end

    # 확장 지역 코드 목록
    def extended_codes
      EXTENDED_REGIONS.keys
    end

    # 전체 지역 코드 목록
    def all_codes
      ALL_REGIONS.keys
    end

    # 지역 코드 유효성 검사 (주요 지역만)
    def valid_primary?(code)
      PRIMARY_REGIONS.key?(code.to_s.upcase)
    end

    # 지역 코드 유효성 검사 (전체 지역)
    def valid?(code)
      ALL_REGIONS.key?(code.to_s.upcase)
    end

    # 지역 정보 가져오기
    def info(code)
      ALL_REGIONS[code.to_s.upcase]
    end

    # 지역명 가져오기
    def name(code)
      info(code)&.dig(:name) || code.to_s.upcase
    end

    # 이모지 가져오기
    def emoji(code)
      info(code)&.dig(:emoji) || '🌍'
    end

    # 언어 코드 가져오기
    def language(code)
      info(code)&.dig(:language) || 'en'
    end

    # Bootstrap 색상 가져오기
    def color(code)
      info(code)&.dig(:color) || 'secondary'
    end

    # 표시용 이름 (이모지 + 이름)
    def display_name(code)
      region_info = info(code)
      return code.to_s.upcase unless region_info
      "#{region_info[:emoji]} #{region_info[:name]}"
    end

    # 셀렉트 옵션용 배열 (주요 지역만)
    def primary_options
      PRIMARY_REGIONS.map do |code, info|
        ["#{info[:emoji]} #{info[:name]}", code]
      end
    end

    # 셀렉트 옵션용 배열 (전체 지역)
    def all_options
      ALL_REGIONS.map do |code, info|
        ["#{info[:emoji]} #{info[:name]}", code]
      end
    end

    # 지역별 통계용 배열 (주요 지역 중 상위 6개국만)
    def stats_regions
      PRIMARY_REGIONS.first(6).map do |code, info|
        [code, info[:name]]
      end
    end

    # 관리자 페이지용 지역 버튼 정보
    def admin_buttons
      PRIMARY_REGIONS.map do |code, info|
        [info[:emoji] + ' ' + info[:name], code, info[:color]]
      end
    end

    # 유효하지 않은 지역 코드를 기본값으로 변환
    def normalize(code)
      valid?(code) ? code.to_s.upcase : DEFAULT_REGION
    end

    # 주요 지역에서 유효하지 않은 코드를 기본값으로 변환
    def normalize_primary(code)
      valid_primary?(code) ? code.to_s.upcase : DEFAULT_REGION
    end
  end
end