class GlobalConfig
  VERSION = 'V1'.freeze
  KEY_PREFIX = 'GLOBAL_CONFIG'.freeze
  DEFAULT_EXPIRY = 1.day

  class << self
    def get(*args)
      config_keys = *args
      config = {}

      # In-memory fast cache to avoid multiple remote Redis/Postgres round-trips per request
      @mem_cache ||= {}
      @mem_cache_expires_at ||= Time.current

      if Time.current > @mem_cache_expires_at
        @mem_cache.clear
        @mem_cache_expires_at = Time.current + 5.minutes
      end

      missing_keys = config_keys.reject { |k| @mem_cache.key?(k) }

      if missing_keys.any?
        missing_keys.each do |config_key|
          @mem_cache[config_key] = load_from_cache(config_key)
        end
      end

      config_keys.each do |k|
        config[k] = @mem_cache[k]
      end

      typecast_config(config)
      config.with_indifferent_access
    end

    def get_value(arg)
      get(arg)[arg]
    end

    def clear_cache
      @mem_cache&.clear
      @mem_cache_expires_at = Time.current - 1.second
      $alfred.with do |conn|
        cached_keys = conn.scan_each(match: "#{VERSION}:#{KEY_PREFIX}:*", count: 1000).to_a
        conn.del(*cached_keys) if cached_keys.any?
      end
    rescue StandardError => e
      Rails.logger.warn "GlobalConfig.clear_cache error: #{e.message}"
    end

    private

    def typecast_config(config)
      general_configs = ConfigLoader.new.general_configs
      config.each do |config_key, config_value|
        config_type = general_configs.find { |c| c['name'] == config_key }&.dig('type')
        config[config_key] = ActiveRecord::Type::Boolean.new.cast(config_value) if config_type == 'boolean'
      end
    end

    def load_from_cache(config_key)
      cache_key = "#{VERSION}:#{KEY_PREFIX}:#{config_key}"
      cached_value = $alfred.with { |conn| conn.get(cache_key) }

      if cached_value.blank?
        value_from_db = db_fallback(config_key)
        cached_value = { value: value_from_db }.to_json
        $alfred.with { |conn| conn.set(cache_key, cached_value, { ex: DEFAULT_EXPIRY }) }
      end

      JSON.parse(cached_value)['value']
    rescue StandardError => e
      Rails.logger.warn "GlobalConfig.load_from_cache error for #{config_key}: #{e.message}"
      db_fallback(config_key)
    end

    def db_fallback(config_key)
      InstallationConfig.find_by(name: config_key)&.value
    rescue StandardError => e
      Rails.logger.warn "GlobalConfig.db_fallback error for #{config_key}: #{e.message}"
      nil
    end
  end
end
