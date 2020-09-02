// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss";
import "phoenix_html";
import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const Hooks = {};

Hooks.swiperViewport = {
  updated() {
    const list = document.querySelector(".swiper-items");
    const items = Array.from(document.querySelectorAll(".swiper-item"));
    const indicators = Array.from(
      document.querySelectorAll(".swiper-indicator")
    );

    const observer = new IntersectionObserver(onIntersectionObserved, {
      root: list,
      threshold: 0.6
    });

    function onIntersectionObserved(entries) {
      entries.forEach(entry => {
        // On page load, firefox claims item with index 1 isIntersecting,
        // while intersectionRatio is 0
        if (entry.isIntersecting && entry.intersectionRatio >= 0.6) {
          const intersectingIndex = items.indexOf(entry.target);
          activateIndicator(intersectingIndex);
        }
      });
    }

    function activateIndicator(index) {
      indicators.forEach((indicator, i) => {
        indicator.classList.toggle("active", i === index);
      });
    }

    items.forEach(item => {
      observer.observe(item);
    });
  }
};

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

window.liveSocket = liveSocket;
