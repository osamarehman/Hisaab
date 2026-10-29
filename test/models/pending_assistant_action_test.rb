require "test_helper"

class PendingAssistantActionTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    @chat = chats(:one)
    @chat.update!(confirm_writes: true)
    @account = accounts(:depository)
    @category = categories(:food_and_drink)
    @arguments = {
      "account_id" => @account.id,
      "date" => Date.current.iso8601,
      "amount" => 2500,
      "type" => "expense",
      "name" => "Sabzi",
      "category_id" => @category.id
    }
  end

  test "a write tool in a confirm-writes chat is proposed, not run" do
    caller = Assistant::FunctionToolCaller.new(
      [ Assistant::Function::CreateTransaction.new(@user) ],
      confirm_writes_chat: @chat
    )

    assert_no_difference "Entry.count" do
      assert_difference "PendingAssistantAction.count", 1 do
        @result = caller.fulfill_requests([ function_request("create_transaction", @arguments) ]).first.function_result.with_indifferent_access
      end
    end

    assert_equal "awaiting_confirmation", @result[:status]
    action = PendingAssistantAction.find(@result[:pending_action_id])
    assert_equal "create_entry", action.kind
    assert_equal "pending", action.status
    assert_equal "call_1", action.provider_call_id
    assert_equal "out", action.details["direction"]
    assert_equal "Food & Drink", action.details["label"]
    assert_includes action.summary, @account.name
  end

  test "read tools still run directly in a confirm-writes chat" do
    caller = Assistant::FunctionToolCaller.new([ Assistant::Function::GetAccounts.new(@user) ], confirm_writes_chat: @chat)

    assert_no_difference "PendingAssistantAction.count" do
      result = caller.fulfill_requests([ function_request("get_accounts", {}) ]).first.function_result
      assert result["accounts"].present?
    end
  end

  test "an invalid proposal returns the tool's error and stores nothing" do
    assert_no_difference "PendingAssistantAction.count" do
      result = PendingAssistantAction.propose!(
        chat: @chat,
        function: Assistant::Function::CreateTransaction.new(@user),
        arguments: @arguments.merge("account_id" => SecureRandom.uuid)
      )
      assert_equal false, result[:success]
      assert_equal "account_not_found", result[:error]
    end
  end

  test "apply writes once and records the outcome on the tool call" do
    action = propose
    message = AssistantMessage.create!(chat: @chat, content: "Tap Save", ai_model: "gpt-4.1")
    message.tool_calls.create!(type: "ToolCall::Function", provider_id: "p1", provider_call_id: "call_1",
                               function_name: "create_transaction", function_arguments: @arguments, function_result: { status: "awaiting_confirmation" })
    action.update!(message: message)

    assert_difference "Entry.count", 1 do
      action.apply!
      action.apply!
    end

    assert action.reload.applied?
    assert action.result["transaction"]["id"].present?
    assert_equal "saved_after_user_confirmed", message.tool_calls.first.reload.function_result["status"]
  end

  test "cancel writes nothing and cannot be applied afterwards" do
    action = propose
    action.cancel!

    assert_no_difference "Entry.count" do
      action.apply!
    end
    assert action.reload.cancelled?
  end

  test "a tool error on apply marks the action failed with the message" do
    action = propose
    action.update!(arguments: @arguments.merge("account_id" => SecureRandom.uuid))

    action.apply!

    assert action.reload.failed?
    assert action.error.present?
  end

  test "a write tool without a card preview is refused, not proposed" do
    caller = Assistant::FunctionToolCaller.new([ Assistant::Function::CreateRule.new(@user) ], confirm_writes_chat: @chat)

    assert_no_difference [ "PendingAssistantAction.count", "Rule.count" ] do
      result = caller.fulfill_requests([ function_request("create_rule", { "name" => "x" }) ]).first.function_result
      assert_equal "not_available_in_app", result["error"]
    end
  end

  test "read tools are an explicit list from the registry" do
    registry = Assistant.function_classes(users(:family_admin).tap { |u| u.stubs(:preview_features_enabled?).returns(true) })

    assert_empty Assistant::READ_FUNCTION_CLASSES - registry
    assert Assistant::Function::GetAccounts.requires_confirmation? == false
    assert Assistant::Function::CreateTransaction.requires_confirmation?
    assert Assistant::Function::ImportBankStatement.requires_confirmation?
  end

  test "a tool that reports failure after writing leaves nothing behind" do
    failing = Class.new(Assistant::Function) do
      def self.name = "create_category"
      def self.description = "writes, then fails"
      def call(_params = {})
        family.categories.create!(name: "Half written")
        { success: false, error: "boom", message: "boom" }
      end
    end
    action = propose
    action.update!(function_name: "create_category")
    Assistant.stubs(:function_classes).returns([ failing ])

    assert_no_difference "Category.count" do
      action.apply!
    end
    assert action.reload.failed?
  end

  test "one failing action does not stop or undo the others in a confirm" do
    good = propose
    bad = propose
    bad.stubs(:apply!).raises(RuntimeError, "db went away")

    result = PendingAssistantAction.confirm_all!([ good, bad ])

    assert_equal %w[applied failed], result.map(&:status)
  end

  test "a turn links only the actions it proposed and withdraws them if it fails" do
    stale = propose
    builtin = Assistant::Builtin.new(@chat, functions: [ Assistant::Function::CreateTransaction ])
    builtin.stubs(:get_model_provider).returns(mock("llm"))
    builtin.send(:function_tool_caller).fulfill_requests([ function_request("create_transaction", @arguments.merge("name" => "Doodh")) ])
    proposed = PendingAssistantAction.find(builtin.send(:function_tool_caller).proposed_action_ids.first)

    message = AssistantMessage.create!(chat: @chat, content: "Tap Save", ai_model: "gpt-4.1")
    Assistant::Responder.any_instance.stubs(:respond)
    builtin.respond_to(UserMessage.new(chat: @chat, content: "doodh 200", ai_model: "gpt-4.1"), assistant_message: message)

    assert_equal message.id, proposed.reload.message_id
    assert_nil stale.reload.message_id

    failing = Assistant::Builtin.new(@chat, functions: [ Assistant::Function::CreateTransaction ])
    failing.stubs(:get_model_provider).returns(mock("llm"))
    failing.send(:function_tool_caller).fulfill_requests([ function_request("create_transaction", @arguments) ])
    orphan = PendingAssistantAction.find(failing.send(:function_tool_caller).proposed_action_ids.first)
    Assistant::Responder.any_instance.stubs(:respond).raises(StandardError, "provider down")
    failing.respond_to(UserMessage.new(chat: @chat, content: "x", ai_model: "gpt-4.1"))

    assert orphan.reload.cancelled?
    assert stale.reload.pending?
  end

  private
    def propose
      result = PendingAssistantAction.propose!(
        chat: @chat,
        function: Assistant::Function::CreateTransaction.new(@user),
        arguments: @arguments,
        provider_call_id: "call_1"
      )
      PendingAssistantAction.find(result[:pending_action_id])
    end

    def function_request(name, args)
      Provider::LlmConcept::ChatFunctionRequest.new(id: "p1", call_id: "call_1", function_name: name, function_args: args.to_json)
    end
end
