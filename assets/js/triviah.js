import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";

// import "../css/setup.scss";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const hooks = {};

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

window.liveSocket = liveSocket;
