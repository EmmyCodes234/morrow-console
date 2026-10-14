FROM chatwoot/chatwoot:v4.18.0

USER root

# 1. Inject Morrow Brand Assets
COPY public/brand-assets/logo.svg /app/public/brand-assets/logo.svg
COPY public/brand-assets/logo_dark.svg /app/public/brand-assets/logo_dark.svg
COPY public/brand-assets/logo_thumbnail.svg /app/public/brand-assets/logo_thumbnail.svg
COPY public/manifest.json /app/public/manifest.json

# 2. Inject Morrow Configurations, Views & Database config
COPY config/installation_config.yml /app/config/installation_config.yml
COPY config/database.yml /app/config/database.yml
COPY config/application.rb /app/config/application.rb
COPY config/environments/production.rb /app/config/environments/production.rb
COPY app/views/layouts/vueapp.html.erb /app/app/views/layouts/vueapp.html.erb

# 3. Inject Morrow WhatsApp, Telegram, Health, Onboarding & Performance Handlers
COPY app/controllers/health_controller.rb /app/app/controllers/health_controller.rb
COPY app/controllers/api/v1/accounts/onboardings_controller.rb /app/app/controllers/api/v1/accounts/onboardings_controller.rb
COPY app/controllers/webhooks/whatsapp_controller.rb /app/app/controllers/webhooks/whatsapp_controller.rb
COPY app/controllers/webhooks/telegram_controller.rb /app/app/controllers/webhooks/telegram_controller.rb
COPY app/jobs/webhooks/whatsapp_events_job.rb /app/app/jobs/webhooks/whatsapp_events_job.rb
COPY app/services/whatsapp/incoming_message_whatsapp_cloud_service.rb /app/app/services/whatsapp/incoming_message_whatsapp_cloud_service.rb
COPY app/models/message.rb /app/app/models/message.rb
COPY lib/global_config.rb /app/lib/global_config.rb
COPY lib/global_config_service.rb /app/lib/global_config_service.rb

# 4. Inject dedicated Render entrypoint
COPY render-entrypoint.sh /app/render-entrypoint.sh
RUN chmod +x /app/render-entrypoint.sh

# 5. Deep-patch precompiled bundles (rebrand color to emerald, simple terminology, strip emojis)
COPY scripts/patch_bundles.js /app/scripts/patch_bundles.js
RUN node /app/scripts/patch_bundles.js /app/public/vite /app/public/packs

WORKDIR /app
EXPOSE 3000

ENTRYPOINT ["/app/render-entrypoint.sh"]
