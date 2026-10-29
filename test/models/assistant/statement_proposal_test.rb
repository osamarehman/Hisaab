require "test_helper"

class Assistant::StatementProposalTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:family_admin)
    @chat = chats(:one)
    @import = imports(:pdf_with_rows)
    @import.update_column(:account_id, accounts(:depository).id)
    @import.generate_rows_from_extracted_data
    @import.sync_mappings
    @proposal = Assistant::StatementProposal.new(chat: @chat, import: @import)
  end

  test "waits while the statement is still being read" do
    @import.update!(status: :importing)

    assert_no_difference "Message.count" do
      assert_equal :wait, @proposal.propose!
    end
  end

  test "posts a summary and one pending line per row with suggested labels" do
    message = nil
    assert_difference "PendingAssistantAction.count", 2 do
      message = @proposal.propose!(file_name: "march.pdf")
    end

    assert_kind_of AssistantMessage, message
    assert_includes message.content, "march.pdf"

    lines = @chat.pending_assistant_actions.where(message: message).ordered
    assert lines.all? { |line| line.kind == "statement_entry" && line.pending? }
    coffee = lines.find { |line| line.details["description"] == "Coffee Shop" }
    assert_equal "Food & Drink", coffee.details["label"]
    assert_equal false, coffee.details["duplicate"]
  end

  test "suggests a label from a keyword rule when the statement names none" do
    rent = categories(:one)
    Rule.create_keyword_category_rule!(@import.family, keyword: "salary", category: rent)
    @import.rows.update_all(category: "")

    message = @proposal.propose!
    salary = @chat.pending_assistant_actions.where(message: message).find { |l| l.details["description"] == "Salary" }

    assert_equal rent.name, salary.details["label"]
  end

  test "saving keeps only confirmed lines and publishes the import once" do
    message = @proposal.propose!
    coffee, salary = @chat.pending_assistant_actions.where(message: message).ordered.partition { |l| l.details["description"] == "Coffee Shop" }.map(&:first)

    assert_enqueued_jobs 1, only: ImportJob do
      PendingAssistantAction.confirm_all!([ PendingAssistantAction.find(coffee.id) ])
      PendingAssistantAction.confirm_all!([ PendingAssistantAction.find(coffee.id) ])
    end

    assert coffee.reload.applied?
    assert salary.reload.cancelled?
    assert_equal [ coffee.arguments["row_id"] ], @import.rows.reload.pluck(:id)
    assert_equal 1, @import.reload.rows_count
    assert @import.importing?
  end
end
