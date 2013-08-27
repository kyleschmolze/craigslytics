# Load the rails application
require File.expand_path('../application', __FILE__)

# Testing UTF-8 bug fix
#Encoding.default_external = Encoding::UTF_8
#Encoding.default_internal = Encoding::UTF_8

# Initialize the rails application
Craigslytics::Application.initialize!

# Default URL for Devise
# config.action_mailer.default_url_options = { :host => 'localhost:3000' }
# config.action_mailer.default_url_options = { :host => 'rentalyzer.com' }
