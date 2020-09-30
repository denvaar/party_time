defmodule PartyTimeWeb.TriviahView do
  use PartyTimeWeb, :view

  def render("scripts.html", _assigns) do
    href = Routes.static_path(PartyTimeWeb.Endpoint, "/css/triviah.css")
    src = Routes.static_path(PartyTimeWeb.Endpoint, "/js/triviah.js")

    ~E(<link rel="stylesheet" href="<%= href %>"/><script type="text/javascript" src="<%= src %>"></script>)
  end
end
