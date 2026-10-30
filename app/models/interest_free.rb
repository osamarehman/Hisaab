# Hisaab runs interest-free (no riba) by default: loans repay principal only,
# interest and APR inputs are hidden, and activity labelled "Interest" is not
# counted as income. Set INTEREST_FREE=false for the conventional behaviour.
#
# Every interest-free branch asks this predicate, so tests stub one method and
# the switch is read from configuration in one place.
module InterestFree
  def self.enabled?
    Rails.configuration.x.interest_free != false
  end
end
