# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

gem "decidim", git: "https://github.com/OpenSourcePolitics/decidim.git", branch: "alt/petition_merge"
gem "decidim-initiatives", git: "https://github.com/OpenSourcePolitics/decidim.git", branch: "alt/petition_merge"

gem "decidim-term_customizer", git: "https://github.com/OpenSourcePolitics/decidim-module-term_customizer.git", branch: "0.dev"

gem "bootsnap"
gem "puma", ">= 4.3"
gem "uglifier"

gem "faker", "~> 1.9"

# Avoid wicked_pdf require error
gem "wicked_pdf"
gem "wkhtmltopdf-binary"

gem "activerecord-session_store"

gem "omniauth_openid_connect", "0.3.1"
gem "openid_connect", "~> 1.3"

gem "ruby-progressbar"
gem "rubyzip", require: "zip"
gem "sentry-raven"

gem "dotenv-rails"
gem "rails", "5.2.4.4"
gem 'health_check'

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri

  gem "decidim-dev", git: "https://github.com/OpenSourcePolitics/decidim.git", branch: "alt/petition_merge"
end

group :development do
  gem "letter_opener_web", "~> 1.3"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 3.5"
end

group :production do
  gem "aws-sdk-s3"
  gem "dalli"
  gem "dalli-elasticache"
  gem "fog-aws"
  gem "hiredis"
  gem "lograge"
  gem "newrelic_rpm"
  gem "passenger"
  gem "redis"
  gem "sendgrid-ruby"
  gem "sidekiq"
  gem "sidekiq-scheduler"
end
