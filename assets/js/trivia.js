import { Socket } from "phoenix";
import LiveSocket from "phoenix_live_view";

import "../css/setup.scss";
import "../css/lobby.scss";
import "../css/trivia.scss";

const intersectionObserver = (swiperViewportId, ref) => {
  const list = document
    .getElementById(swiperViewportId)
    .querySelector(".swiper-items");

  const items = Array.from(list.querySelectorAll(".item"));
  const indicators = Array.from(
    document
      .getElementById(swiperViewportId)
      .querySelectorAll(".swiper-indicator")
  );

  const observer = new IntersectionObserver(onIntersectionObserved, {
    root: list,
    threshold: 0.6,
  });

  function onIntersectionObserved(entries) {
    entries.forEach((entry) => {
      // On page load, firefox claims item with index 1 isIntersecting,
      // while intersectionRatio is 0
      if (entry.isIntersecting && entry.intersectionRatio >= 0.6) {
        const intersectingIndex = items.indexOf(entry.target);
        activateIndicator(intersectingIndex);
        if (ref.el.dataset.incontrol === "true") {
          ref.pushEvent("select-category", {
            selected_category: entry.target.dataset.category,
          });
        }
      }
    });
  }

  function activateIndicator(index) {
    indicators.forEach((indicator, i) => {
      indicator.classList.toggle("active", i === index);
    });
  }

  items.forEach((item) => {
    observer.observe(item);
  });

  return observer;
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const hooks = {};

let notifyTriggered = false;
const notify = (e) => {
  e.preventDefault();
  if (!notifyTriggered) {
    notifyTriggered = true;
    const controlNotification = document.getElementById("control-notification");
    if (controlNotification) {
      controlNotification.classList.add("reveal");

      setTimeout(() => {
        controlNotification.classList.remove("reveal");
        notifyTriggered = false;
      }, 3000);
    }
  }
};

const removeEventListeners = (target) => {
  const clickArea = document.getElementById("click-area");
  target.removeEventListener("click", notify);
  target.removeEventListener("touchstart", notify);
  target.removeEventListener("touchmove", notify);

  if (clickArea) {
    clickArea.removeEventListener("click", notify);
    clickArea.removeEventListener("touchstart", notify);
  }
};

hooks.categorySwiper = {
  unmounted() {
    removeEventListeners(this.el);
  },
  mounted() {
    const selectedCategory = document.getElementById(
      this.el.dataset.selectedcategory
    );
    if (selectedCategory) {
      selectedCategory.scrollIntoView({ behavior: "smooth" });
    }
    intersectionObserver("category-swiper", this);

    const clickArea = document.getElementById("click-area");

    if (this.el.dataset.incontrol !== "true") {
      this.el.addEventListener("click", notify);
      this.el.addEventListener("touchstart", notify);
      this.el.addEventListener("touchmove", notify);

      if (clickArea) {
        clickArea.addEventListener("click", notify);
        clickArea.addEventListener("touchstart", notify);
      }
    } else {
      removeEventListeners(this.el);
    }
  },
};

window.Clipboard = (function(window, document, navigator) {
  var textArea, copy;

  function isOS() {
    return navigator.userAgent.match(/ipad|iphone/i);
  }

  function createTextArea(text) {
    textArea = document.createElement("textArea");
    textArea.value = text;
    document.body.appendChild(textArea);
  }

  function selectText() {
    var range, selection;

    if (isOS()) {
      range = document.createRange();
      range.selectNodeContents(textArea);
      selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      textArea.setSelectionRange(0, 999999);
    } else {
      textArea.select();
    }
  }

  function copyToClipboard() {
    document.execCommand("copy");
    document.body.removeChild(textArea);
  }

  copy = function(text) {
    createTextArea(text);
    selectText();
    copyToClipboard();
  };

  return {
    copy: copy,
  };
})(window, document, navigator);

hooks.copyToClipboard = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      Clipboard.copy(window.location.href);
      e.target.innerText = "✅ Copied!";
      setTimeout(() => {
        e.target.innerText = "📋 Copy Invite Link";
      }, 1000);
    });
  },
};

hooks.selectedCategory = {
  mounted() {
    document
      .getElementById(this.el.value)
      .scrollIntoView({ behavior: "smooth" });
  },
  updated() {
    document
      .getElementById(this.el.value)
      .scrollIntoView({ behavior: "smooth" });
  },
};

hooks.answerButtonContainer = {
  mounted() {
    if (!this.el.classList.contains("slide-in-second")) {
      this.el.classList.add("slide-in-second");
    }
  },
  destroyed() {
    this.el.classList.remove("slide-in-second");
  },
};

hooks.hostView = {
  mounted() {
    window.onbeforeunload = function(e) {
      delete e["returnValue"];
      return "Are you sure you want to leave?";
    };
  },
};

hooks.lobbyPlayers = {
  updated() {
    const playerList = document.getElementById("player-list");
    const sourceOfTruthIds = Array.from(this.el.querySelectorAll("li")).map(
      (li) => {
        return li.dataset.playerid;
      }
    );
    const animatedIds = Array.from(playerList.querySelectorAll(".lobby-player"))
      .filter((div) => div.id !== "nextplayer")
      .map((div) => div.id.split("-")[1])
      .filter((id) => id);

    // does the animated list view contain any players that are not reflected
    // in the source of truth list?
    const idsToRemove = animatedIds.filter(
      (id) => !sourceOfTruthIds.includes(id)
    );

    if (idsToRemove.length > 0) {
      idsToRemove.forEach((id) => {
        const div = document.getElementById("id-" + id);
        playerList.removeChild(div);
      });

      return;
    }

    if (timeoutId) {
      clearTimeout(timeoutId);
      timeoutId = null;
    }

    let nextPlayerDiv = document.getElementById("nextplayer");
    if (!nextPlayerDiv) {
      playerList.insertAdjacentHTML(
        "afterbegin",
        '<div id="nextplayer" class="lobby-player empty"> <div class="player-picture item"> <div></div> </div> <div class="item">Who\'s next??</div> </div>'
      );
      nextPlayerDiv = document.getElementById("nextplayer");
    }
    const newPlayerDiv = nextPlayerDiv.cloneNode(true);

    newPlayerDiv.style = "--animation-delay: 0";
    newPlayerDiv.lastElementChild.innerText = this.el.firstElementChild.dataset.playername;

    const avatarImg = document.createElement("img");
    avatarImg.src = this.el.firstElementChild.dataset.avatarurl;
    avatarImg.referrerpolicy = "no-referrer";
    const avatarContainer = newPlayerDiv.querySelector(".player-picture");
    avatarContainer.replaceChild(avatarImg, avatarContainer.firstElementChild);

    newPlayerDiv.id = "id-" + this.el.firstElementChild.dataset.playerid;
    newPlayerDiv.classList.remove("empty");

    const blankPlayerDiv = nextPlayerDiv.cloneNode(true);
    blankPlayerDiv.style = "--animation-delay: 0";
    nextPlayerDiv.parentNode.replaceChild(newPlayerDiv, nextPlayerDiv);

    var timeoutId = setTimeout(function() {
      if (
        blankPlayerDiv &&
        newPlayerDiv &&
        newPlayerDiv.parentNode === playerList
      ) {
        playerList.insertBefore(blankPlayerDiv, newPlayerDiv);
      }
    }, 500);
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: hooks,
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

window.liveSocket = liveSocket;
