require 'ostruct'

class AppsController < ApplicationController

  def index
    @type = params[:type]
    @owner = params[:owner]
    @title = nil
    @apps = []

    # once these work, we can decide what to do
    # as far as mixing and matching lists of apps
    if @type == "dev"
      @apps += DevRouter.apps
      @title = "Your Dev"
    elsif @type == "usr"
      @apps += UsrRouter.apps(owner: @owner)
      @title = @owner
    elsif @type == "sys"
      @apps += SysRouter.apps
      @title = "OSC's"
    else
      raise ActionController::RoutingError.new('Not Found') unless app.accessible?
    end
  end

  def show
    set_app

    raise ActionController::RoutingError.new('Not Found') unless @app.accessible?

    #FIXME: the only thing about this action that feels wrong
    #is it is a GET and we are doing a setup (changing something) in response to
    #this request
    @app.run_setup_production

    app_url = @app.url

    if params[:path]
      # if a path in the app is provided, append this to the url
      app_uri = uri(app_url)
      app_uri.path = Pathname.new(app_uri.path).join(params[:path]).to_s
      app_url = app_uri.to_s
    end

    redirect_to app_url

  rescue ::OodApp::SetupScriptFailed => e
    #FIXME: should this be 500 error?
    #FIXME: how we handle setup script failure (etc.) needs rethough and tested
    @app_url = @app.url
    @exception = e
    render "setup_failed"
  end

  def icon
    set_app

    # raise ActionController::RoutingError.new('Not Found') unless @app.icon_path.file?
    # TODO: if icon file doesn't exist, return default image instead

    send_file @app.icon_path, :type => 'image/png', :disposition => 'inline'
  end

  private

  def set_app
    @app = ::OodApp.new(router_for_type(params[:type], params[:owner], params[:name], params[:path]))
  end

  # keyword args?
  def router_for_type(type, owner, app_name, path)
    if type.to_sym == :sys
      ::SysRouter.new(app_name)
    elsif type.to_sym == :usr
      ::UsrRouter.new(app_name, owner)
    elsif type.to_sym == :dev
      # FIXME: right now just return my dev apps router
      ::DevRouter.new(app_name)
    else
      #FIXME: app type doesn't exit
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end