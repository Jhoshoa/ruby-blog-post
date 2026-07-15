class Current < ActiveSupport::CurrentAttributes
  attribute :user

  def user=(user)
    super
    self.request_id = Current.request_id if user
  end

  # Allows tracking request context
  attribute :request_id
end
