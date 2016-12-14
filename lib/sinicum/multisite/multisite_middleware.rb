module Sinicum
  module Multisite
    class MultisiteMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        session = ActionDispatch::Request::Session.find(env)
        log("Sinicum-Multisite Header => #{request.headers['Sinicum-Multisite']}")
        log("Sinicum-Multisite env => #{env['sinicum.multisite']} | #{env['Sinicum-Multisite']}")
        log("Session id => #{session.id}")
        log("Session loaded? => #{session.loaded?}")
        session.delete 'sinicum-init'
        log("Session loaded? => #{session.loaded?}")
        path = request.path.gsub(".html", "")
        unless multisite_ignored_path?(env)
          if Rails.configuration.x.multisite_production == true
            node = node_from_domain(request.host, :primary_domain)
            if node.nil?
              # Alias domain handling - redirect to the primary domain
              node = node_from_domain(request.host, :alias_domains)
              return redirect("#{node[:primary_domain]}#{request.fullpath}") if node
            else
              session[:multisite_root] = node[:root_node]
            end
          else # author/dev
            log("Session => #{session[:multisite_root].inspect}")
            query = "select * from mgnl:multisite where root_node LIKE '#{root_from_path(path)}'"
            if node = Sinicum::Jcr::Node.query(:multisite, :sql, query).first
              # Node has been found, so the session is set
              log("Node has been found - Session => #{node[:root_node].inspect}")
              session[:multisite_root] = node[:root_node]
            end
            if on_root_path?(session[:multisite_root], request.fullpath)
              # Redirect to the fullpath without the root_path for consistency
              env['multisite.redirect'] = gsub_root_path(session[:multisite_root], request.fullpath)
            end
          end
        end
        status, headers, response =
          @app.call(adjust_paths(env, session[:multisite_root]))
        [status, headers, response]
      end

      private
      def log(msg)
        Rails.logger.info("  Sinicum Multisite:" + msg) if Rails.configuration.x.multisite_logging
      end

      def node_from_domain(domain, type)
        Rails.cache.fetch("sinicum-multisite-node-#{type}-#{domain}", expires: 1.hour) do
          query = "select * from mgnl:multisite where #{type} LIKE '%//#{domain}%'"
          Sinicum::Jcr::Node.query(:multisite, :sql, query).first
        end
      end

      def on_root_path?(root_path, path)
        !!(root_path && path.match(/^(#{root_path})\//))
      end

      def gsub_root_path(root_path, path)
        clean_path = path.gsub(root_path, '').gsub(".html", '')
        clean_path.empty? ? '/' : clean_path
      end

      def adjust_paths(env, root_path)
        return env if multisite_ignored_path?(env) || root_path.nil?
        return env if env['PATH_INFO'].start_with?(root_path) &&
          Rails.configuration.x.multisite_production != true
        %w(REQUEST_PATH PATH_INFO REQUEST_URI ORIGINAL_FULLPATH).each do |env_path|
          env[env_path] = "#{root_path}#{env['PATH_INFO']}"
        end
        env
      end

      def root_from_path(path)
        path.gsub(/(^\/.*?)\/.*/, '\1')
      end

      def multisite_ignored_path?(env)
        Rails.configuration.x.multisite_ignored_paths
          .collect{ |x| !!(x.match(env['PATH_INFO'])) }
          .include?(true)
      end

      def redirect(location, root_path)
        log("REDIRECT INITIALIZED")
        [302, { 'Location' => location, 'Content-Type' => 'text/html', 'Sinicum-Multisite' => root_path }, ['Moved Permanently']]
      end
    end
  end
end
