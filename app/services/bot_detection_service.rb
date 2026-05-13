# app/services/bot_detection_service.rb
class BotDetectionService
  BOT_PATTERNS = [
    /bot/i, /spider/i, /crawler/i, /slurp/i,
    /googlebot/i, /bingbot/i, /yandexbot/i, /ahrefs/i,
    /gptbot/i, /headlesschrome/i, /lighthouse/i
  ]

  def self.bot?(user_agent)
    return false if user_agent.blank?
    BOT_PATTERNS.any? { |pattern| user_agent =~ pattern }
  end
end
