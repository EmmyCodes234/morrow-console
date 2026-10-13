class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  before_action :verify_meta_signature!, only: :process_payload

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    return render json: { status: 'tracking_events_only' } if tracking_events_only?

    result = { status: 'ok' }
    begin
      payload_hash = params.to_unsafe_hash.with_indifferent_access
      job = Webhooks::WhatsappEventsJob.new
      channel = job.find_channel_from_whatsapp_business_payload(payload_hash)
      if channel.present?
        sender_id = job.contact_sender_id(payload_hash)
        job.process_events(channel, payload_hash, sender_id)
        result[:processed] = true
        result[:channel_id] = channel.id
        result[:messages_count] = Message.count
        result[:conversations_count] = Conversation.count
      else
        Rails.logger.warn("Could not find WhatsApp channel for payload: #{params[:phone_number]}")
        result[:processed] = false
        result[:reason] = 'channel_not_found'
      end
    rescue StandardError => e
      Rails.logger.error("Error processing WhatsApp webhook: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
      result[:error] = e.message
      result[:backtrace] = e.backtrace&.first(10)
    end
    render json: result, status: :ok
  end

  private

  def tracking_events_only?
    return false unless params[:object] == 'whatsapp_business_account'

    changes = params.fetch(:entry, []).flat_map { |entry| entry.fetch(:changes, []) }
    changes.present? && changes.all? { |change| change[:field] == 'tracking_events' }
  end

  def find_channel_by_phone
    raw_number = params[:phone_number].to_s.strip
    return if raw_number.blank?

    digits = raw_number.gsub(/[^0-9]/, '')
    Channel::Whatsapp.find_by(phone_number: "+#{digits}") || Channel::Whatsapp.find_by(phone_number: digits)
  end

  def valid_token?(token)
    channel = whatsapp_channel
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def meta_app_secrets
    [
      *channel_meta_app_secrets(whatsapp_channel),
      GlobalConfigService.load('WHATSAPP_APP_SECRET', nil)
    ]
  end

  def whatsapp_channel
    @whatsapp_channel ||= whatsapp_business_payload_channel || find_channel_by_phone || (Channel::Whatsapp.first if Channel::Whatsapp.count == 1)
  end

  def meta_signature_verification_required?
    return true if whatsapp_channel.blank?
    return false unless whatsapp_channel.provider == 'whatsapp_cloud'
    return true if channel_meta_app_secrets(whatsapp_channel).present?

    whatsapp_channel.provider_config['source'] == 'embedded_signup'
  end

  def whatsapp_business_payload_channel
    return unless params[:object] == 'whatsapp_business_account'

    metadata = params.dig(:entry, 0, :changes, 0, :value, :metadata) ||
               params.dig('entry', 0, 'changes', 0, 'value', 'metadata')
    return if metadata.blank?

    display_number = metadata[:display_phone_number] || metadata['display_phone_number']
    phone_id = metadata[:phone_number_id] || metadata['phone_number_id']

    Whatsapp::WebhookChannelFinderService.new(
      display_phone_number: display_number,
      phone_number_id: phone_id
    ).perform
  end

  def inactive_whatsapp_number?
    phone_number = params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end
end
