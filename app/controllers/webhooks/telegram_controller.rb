class Webhooks::TelegramController < ActionController::API
  def process_payload
    begin
      Webhooks::TelegramEventsJob.perform_now(params.to_unsafe_hash)
    rescue StandardError => e
      Rails.logger.error("[TELEGRAM_WEBHOOK_ERROR] #{e.message}")
    end

    callback_query = params[:callback_query]
    callback_query_id = callback_query[:id] if callback_query.respond_to?(:key?)
    return head :ok unless callback_query_id.is_a?(String) && callback_query_id.present?

    render json: { method: 'answerCallbackQuery', callback_query_id: callback_query_id }
  end
end
