const star = () => {

  const star = document.createElement("span");
  star.classList.add("magic-star");

  const svg = star.appendChild(document.createElementNS("http://www.w3.org/2000/svg", "svg"));
  svg.setAttribute("viewBox", "0 0 512 512");

  const path = svg.appendChild(document.createElementNS("http://www.w3.org/2000/svg", "path"));
  path.setAttribute("d", "M512 255.1c0 11.34-7.406 20.86-18.44 23.64l-171.3 42.78l-42.78 171.1C276.7 504.6 267.2 512 255.9 512s-20.84-7.406-23.62-18.44l-42.66-171.2L18.47 279.6C7.406 276.8 0 267.3 0 255.1c0-11.34 7.406-20.83 18.44-23.61l171.2-42.78l42.78-171.1C235.2 7.406 244.7 0 256 0s20.84 7.406 23.62 18.44l42.78 171.2l171.2 42.78C504.6 235.2 512 244.6 512 255.1z");

  return star;
};

const rand = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

for (const magic of document.querySelectorAll(".magic")) {
  const stars = [star(), star(), star()];

  // don't show on page load; wait for mouseover
  stars.forEach(star => star.style.display = "none");

  stars.forEach(star => magic.appendChild(star));

  let interval;
  magic.addEventListener("mouseover", () => {
    if (interval === undefined) {
      let i = 0;
      interval = setInterval(() => {
        let star = stars[i++];
        i %= stars.length;

        star.style.display = "";

        star.style.left = rand(-20, 80) + "%";
        star.style.top = rand(-20, 80) + "%";


        star.style.animation = "none";
        star.offsetHeight;
        star.style.animation = "";
      }, 250);
    }
  });

  magic.addEventListener("mouseout", () => interval = clearInterval(interval));
}
