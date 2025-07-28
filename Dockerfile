# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t youtube_trends .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name youtube_trends youtube_trends

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.0
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages (SQLite only)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems (SQLite only)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen false && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Make bin files executable
RUN chmod +x bin/*

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompile assets for production (Rails 8 Propshaft)
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy_key_for_asset_precompile bundle exec rails assets:precompile

# Enable static file serving in production (required for containerized environments)
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true




# Final stage for app image
FROM base

# Set production environment variables
ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create necessary directories and set permissions
RUN mkdir -p /rails/storage /rails/db /rails/log /rails/tmp && \
    chmod -R 755 /rails/storage /rails/db /rails/log /rails/tmp

# Railway volumes require root permissions for SQLite file creation
# USER 1000:1000  # Commented out for Railway volume compatibility

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start both Solid Queue worker and Rails server
EXPOSE 3000
CMD ["sh", "-c", "./bin/rails solid_queue:start & ./bin/rails server -b 0.0.0.0 -p ${PORT:-3000}"]
