class CanonicalHostRedirector
  def initialize(app, source_host:, target_host:, skip_paths: [])
    @app = app
    @source_host = source_host
    @target_host = target_host
    @skip_paths = skip_paths
  end

  def call(env)
    request = Rack::Request.new(env)

    if redirect?(request)
      location = "https://#{@target_host}#{request.fullpath}"
      return [ 301, { "Location" => location, "Content-Type" => "text/plain" }, [ "Moved Permanently" ] ]
    end

    @app.call(env)
  end

  private

  def redirect?(request)
    request.host == @source_host && !@skip_paths.include?(request.path)
  end
end
