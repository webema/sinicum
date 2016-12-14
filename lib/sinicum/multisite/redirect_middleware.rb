module Sinicum
  module Multisite
    class RedirectMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        env['multisite.redirect'] ? redirect(env['multisite.redirect']) : @app.call(env)
      end

      private
      def redirect(location)
        [302, { 'Location' => location, 'Content-Type' => 'text/html' }, ['Moved Permanently']]
      end
    end
  end
end
