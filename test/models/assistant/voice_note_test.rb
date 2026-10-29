require "test_helper"

class Assistant::VoiceNoteTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @provider = mock("llm_provider")
    @family.stubs(:llm_provider).returns(@provider)
  end

  test "sends the audio as base64 input_audio to the configured model" do
    wav = wav_bytes(seconds: 1)
    @provider.expects(:transcribe_audio).with do |audio_base64:, format:, model:|
      Base64.strict_decode64(audio_base64) == wav && format == "wav" && model == "google/gemini-2.5-flash"
    end.returns(success_response("aaj 2500 ki sabzi li cash se"))

    transcript = with_env_overrides(AI_TRANSCRIBE_MODEL: nil) { note(wav).transcribe! }

    assert_equal "aaj 2500 ki sabzi li cash se", transcript
  end

  test "AI_TRANSCRIBE_MODEL picks the model" do
    @provider.expects(:transcribe_audio).with { |**kwargs| kwargs[:model] == "google/gemini-3-flash-preview" }.returns(success_response("ok"))

    with_env_overrides(AI_TRANSCRIBE_MODEL: "google/gemini-3-flash-preview") { note(wav_bytes(seconds: 1)).transcribe! }
  end

  test "rejects audio longer than two minutes from the WAV header" do
    @provider.expects(:transcribe_audio).never

    error = assert_raises(Assistant::VoiceNote::Error) { note(wav_bytes(seconds: 130)).transcribe! }
    assert_equal "audio_too_long", error.code
  end

  test "rejects an unknown format, oversize audio and a failed or empty transcription" do
    assert_equal "invalid_audio", assert_raises(Assistant::VoiceNote::Error) { note("x", content_type: "video/mp4", filename: "a.mp4").transcribe! }.code
    assert_equal "audio_too_large", assert_raises(Assistant::VoiceNote::Error) { note("x" * (Assistant::VoiceNote::MAX_BYTES + 1), content_type: "audio/mpeg", filename: "a.mp3").transcribe! }.code

    @provider.stubs(:transcribe_audio).returns(Provider::Response.new(success?: false, data: nil, error: Provider::Error.new("boom")))
    assert_equal "transcription_failed", assert_raises(Assistant::VoiceNote::Error) { note(wav_bytes(seconds: 1)).transcribe! }.code

    @provider.stubs(:transcribe_audio).returns(success_response("  "))
    assert_equal "empty_transcript", assert_raises(Assistant::VoiceNote::Error) { note(wav_bytes(seconds: 1)).transcribe! }.code
  end

  private
    def note(bytes, content_type: "audio/wav", filename: "voice.wav")
      file = Rack::Test::UploadedFile.new(StringIO.new(bytes), content_type, true, original_filename: filename)
      Assistant::VoiceNote.new(family: @family, file: file)
    end

    def success_response(text)
      Provider::Response.new(success?: true, data: text, error: nil)
    end

    # 16 kHz mono 16-bit PCM, silent.
    def wav_bytes(seconds:)
      data = "\0".b * (32_000 * seconds)
      header = [ "RIFF", 36 + data.bytesize, "WAVE", "fmt ", 16, 1, 1, 16_000, 32_000, 2, 16, "data", data.bytesize ]
        .pack("a4Va4a4VvvVVvva4V")
      header + data
    end
end
