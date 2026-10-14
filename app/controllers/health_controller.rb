# Inherits from ActionController::Base to skip all middleware,
# authentication, and callbacks. Used for health checks
class HealthController < ActionController::Base # rubocop:disable Rails/ApplicationController
  def show
    if params[:full] == 'true'
      # Warm up database connection (Neon serverless PostgreSQL)
      ActiveRecord::Base.connection.execute('SELECT 1')
      # Warm up Redis cache connection if available
      begin
        Redis.new(url: ENV['REDIS_URL']).ping if ENV['REDIS_URL'].present?
      rescue StandardError => e
        Rails.logger.warn "HealthController Redis ping: #{e.message}"
      end
    end

    render json: { status: 'ok', service: 'morrow', time: Time.current.iso8601 }
  rescue StandardError => e
    render json: { status: 'degraded', error: e.message }, status: :service_unavailable
  end
end
