class PolishTracking < ApplicationRecord
  def pending
    available.to_i - completed.to_i
  end
end
