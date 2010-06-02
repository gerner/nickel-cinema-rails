# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_nickel-cinema-rails_session',
  :secret      => '8f66ba444d145a6abc0a511c3c97a72208ddc1608f1aa9013bb9661b419efd13a658e37ebe54d6568a022c4cd3ef7778c1a6d6bd12a3e14e2f93ed067515199b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
