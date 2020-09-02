const list = document.querySelector(".swiper-items");
const items = Array.from(document.querySelectorAll(".swiper-item"));
const indicators = Array.from(document.querySelectorAll(".swiper-indicator"));

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
