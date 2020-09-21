defmodule PartyTimeWeb.Router do
  use PartyTimeWeb, :router
  use Pow.Phoenix.Router
  use PowAssent.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_root_layout, {PartyTimeWeb.LayoutView, :root}
    plug :put_secure_browser_headers
  end

  pipeline :skip_csrf_protection do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :hosts_only do
    plug PartyTimeWeb.EnsureRolePlug, :host
  end

  scope "/" do
    pipe_through :skip_csrf_protection

    pow_assent_authorization_post_callback_routes()
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
    pow_assent_routes()
  end

  scope "/", PartyTimeWeb do
    pipe_through [:browser, :protected]

    get "/", PageController, :index
    post "/", PageController, :create
    live "/games/trivia/:game_id", PlayTriviaLive, :index
  end

  scope "/", PartyTimeWeb do
    pipe_through [:browser, :protected, :hosts_only]

    get "/games/trivia", PageController, :new_game
    post "/games/trivia", PageController, :create_game
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PartyTimeWeb.Telemetry
    end
  end

  scope "/", PartyTimeWeb do
    pipe_through [:browser]

    get "/*path", RedirectHome, as: :force_redirect
  end
end
