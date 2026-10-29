require "test_helper"

class Provider::Openai::TranscribeAudioTest < ActiveSupport::TestCase
  setup do
    @provider = Provider::Openai.new("test-token", uri_base: "https://openrouter.ai/api/v1", model: "google/gemma-4-31b-it:free")
  end

  test "sends the audio as input_audio content and returns the transcript" do
    client = @provider.send(:client)
    client.expects(:chat).with do |parameters:|
      content = parameters[:messages].first[:content]
      parameters[:model] == "google/gemini-2.5-flash" &&
        content.last == { type: "input_audio", input_audio: { data: "QUJD", format: "wav" } } &&
        content.first[:text].include?("Roman Urdu")
    end.returns({ "choices" => [ { "message" => { "content" => " aaj 500 ki sabzi \n" } } ] })

    response = @provider.transcribe_audio(audio_base64: "QUJD", format: "wav", model: "google/gemini-2.5-flash")

    assert response.success?
    assert_equal "aaj 500 ki sabzi", response.data
  end
end
