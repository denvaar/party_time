import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";

import "../css/setup.scss";
import "../css/lobby.scss";
import "../css/trivia.scss";
// import "../css/tabs.scss";
// import "../css/swiper.scss";
// import "../css/inputs.scss";
// import "../css/accordian.scss";
// import "../css/gameboard.scss";

// const intersectionObserver = (swiperViewportId, ref) => {
//   const list = document
//     .getElementById(swiperViewportId)
//     .querySelector(".swiper-items");
//
//   const items = Array.from(list.querySelectorAll(".item"));
//   const indicators = Array.from(
//     document
//       .getElementById(swiperViewportId)
//       .querySelectorAll(".swiper-indicator")
//   );
//
//   const observer = new IntersectionObserver(onIntersectionObserved, {
//     root: list,
//     threshold: 0.6,
//   });
//
//   function onIntersectionObserved(entries) {
//     entries.forEach((entry) => {
//       // On page load, firefox claims item with index 1 isIntersecting,
//       // while intersectionRatio is 0
//       if (entry.isIntersecting && entry.intersectionRatio >= 0.6) {
//         const intersectingIndex = items.indexOf(entry.target);
//         activateIndicator(intersectingIndex);
//         if (entry.target.dataset.category_name) {
//           document
//             .getElementById("question-button")
//             .setAttribute(
//               "phx-value-active_category",
//               entry.target.dataset.category_name
//             );
//           document
//             .getElementById("category-button")
//             .setAttribute(
//               "phx-value-active_category",
//               entry.target.dataset.category_name
//             );
//         }
//       }
//     });
//   }
//
//   function activateIndicator(index) {
//     indicators.forEach((indicator, i) => {
//       indicator.classList.toggle("active", i === index);
//     });
//   }
//
//   items.forEach((item) => {
//     observer.observe(item);
//   });
//
//   return observer;
// };
//
let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
//
// var horizontalObserver, verticalObserver;
//
// const Hooks = {};
//
// Hooks.categorySwiper = {
//   mounted() {
//     if (horizontalObserver) {
//       horizontalObserver.disconnect();
//     }
//     horizontalObserver = intersectionObserver("horizontal-swiper", this);
//   },
//   updated() {
//     if (horizontalObserver) {
//       horizontalObserver.disconnect();
//     }
//     horizontalObserver = intersectionObserver("horizontal-swiper", this);
//   },
//   destroyed() {
//     horizontalObserver.disconnect();
//   },
// };
//
// Hooks.questionSwiper = {
//   mounted() {
//     if (verticalObserver) {
//       verticalObserver.disconnect();
//     }
//     verticalObserver = intersectionObserver("vertical-swiper", this);
//   },
//   updated() {
//     if (verticalObserver) {
//       verticalObserver.disconnect();
//     }
//     verticalObserver = intersectionObserver("vertical-swiper", this);
//   },
//   destroyed() {
//     verticalObserver.disconnect();
//   },
// };

const hooks = {};

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

window.liveSocket = liveSocket;
