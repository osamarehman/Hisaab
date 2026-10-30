# Hisaab runs interest-free (no riba) by default: loans repay principal only,
# interest and APR inputs are hidden, and activity labelled "Interest" is not
# counted as income. Set INTEREST_FREE=false for the conventional behaviour.
#
# Every interest-free branch asks this predicate, so tests stub one method and
# the switch is read from configuration in one place.
module InterestFree
  INTEREST_LABEL = "Interest".freeze

  def self.enabled?
    Rails.configuration.x.interest_free != false
  end

  # Investment activity labels a user may pick. "Interest" stays a valid
  # stored label (providers import it, and existing rows keep it) but is not
  # offered when interest-free -- except to the row already carrying it, so
  # re-saving that row's form does not silently clear its label.
  def self.selectable_activity_labels(labels, current: nil)
    return labels unless enabled?

    labels.reject { |label| label == INTEREST_LABEL && current != INTEREST_LABEL }
  end
end
