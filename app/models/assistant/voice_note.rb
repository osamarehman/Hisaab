# frozen_string_literal: true

# A voice note recorded in the assistant chat, transcribed by an
# audio-capable model over the family's OpenAI-compatible provider
# (OpenRouter + Gemini by default). The transcript becomes the user's message.
class Assistant::VoiceNote
  class Error < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end

  MAX_BYTES = 5.megabytes
  MAX_SECONDS = 120
  # Small tolerance for the recorder's own stop timing.
  DURATION_GRACE_SECONDS = 2
  DEFAULT_MODEL = "google/gemini-2.5-flash"

  FORMATS = {
    "audio/wav" => "wav", "audio/x-wav" => "wav", "audio/wave" => "wav", "audio/vnd.wave" => "wav",
    "audio/mpeg" => "mp3", "audio/mp3" => "mp3",
    "audio/mp4" => "m4a", "audio/m4a" => "m4a", "audio/x-m4a" => "m4a",
    "audio/aac" => "aac", "audio/ogg" => "ogg", "audio/flac" => "flac"
  }.freeze
  EXTENSIONS = FORMATS.values.uniq.freeze

  def self.model
    ENV["AI_TRANSCRIBE_MODEL"].presence || DEFAULT_MODEL
  end

  def initialize(family:, file:, duration_ms: nil)
    @family = family
    @file = file
    @duration_ms = duration_ms
  end

  def transcribe!
    format = audio_format
    raise error(:invalid_audio, "invalid_audio") unless format

    bytes = file.read
    raise error(:invalid_audio, "invalid_audio") if bytes.blank?
    raise error(:audio_too_large, "too_large") if bytes.bytesize > MAX_BYTES
    raise error(:audio_too_long, "too_long", seconds: MAX_SECONDS) if too_long?(bytes, format)

    provider = family.llm_provider
    raise error(:transcription_failed, "transcription_failed") unless provider.respond_to?(:transcribe_audio)

    response = provider.transcribe_audio(audio_base64: Base64.strict_encode64(bytes), format: format, model: self.class.model)
    unless response.success?
      Rails.logger.warn("Voice note transcription failed: #{response.error&.class}: #{response.error&.message}")
      raise error(:transcription_failed, "transcription_failed")
    end

    transcript = response.data.to_s.strip
    raise error(:empty_transcript, "empty_transcript") if transcript.empty?

    transcript
  end

  private
    attr_reader :family, :file, :duration_ms

    def audio_format
      FORMATS[file.content_type.to_s.split(";").first.to_s.strip.downcase] ||
        EXTENSIONS.find { |ext| file.original_filename.to_s.downcase.end_with?(".#{ext}") }
    end

    def too_long?(bytes, format)
      seconds = format == "wav" ? wav_seconds(bytes) : nil
      seconds ||= duration_ms.to_f / 1000 if duration_ms.present?
      seconds.to_f > MAX_SECONDS + DURATION_GRACE_SECONDS
    end

    # Length from the WAV header's byte rate, so the limit does not rest on the
    # client's word. nil when the header is not a plain RIFF/WAVE one.
    def wav_seconds(bytes)
      return unless bytes.byteslice(0, 4) == "RIFF" && bytes.byteslice(8, 4) == "WAVE"

      byte_rate = bytes.byteslice(28, 4)&.unpack1("V").to_i
      return unless byte_rate.positive?

      (bytes.bytesize - 44).to_f / byte_rate
    end

    def error(code, key, **options)
      Error.new(code.to_s, I18n.t("assistant.voice.#{key}", **options))
    end
end
