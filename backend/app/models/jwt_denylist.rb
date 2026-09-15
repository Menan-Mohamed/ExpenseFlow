class JwtDenylist < ApplicationRecord
  def self.revoked?(jti)
    exists?(jti: jti)
  end

  # Call periodically (or on each logout) to keep the table small —
  # entries past their natural expiry are useless to keep.
  def self.purge_expired!
    where("expires_at < ?", Time.current).delete_all
  end
end