// Год в подвале
document.getElementById('year').textContent = new Date().getFullYear();

// Прорисовка схемы — один раз, когда доходишь до неё
(function () {
  var fig = document.getElementById('diagram');
  if (!fig || !('IntersectionObserver' in window)) return;

  // длина каждой линии нужна для анимации штриха
  fig.querySelectorAll('.link').forEach(function (p) {
    p.style.setProperty('--len', p.getTotalLength());
  });

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        fig.classList.add('is-live');
        io.disconnect();
      }
    });
  }, { threshold: 0.35 });

  io.observe(fig);
})();

// Копирование почты
document.querySelectorAll('.copy').forEach(function (btn) {
  btn.addEventListener('click', function () {
    var el = document.querySelector(btn.dataset.copy);
    if (!el || !navigator.clipboard) return;
    navigator.clipboard.writeText(el.textContent.trim()).then(function () {
      var old = btn.textContent;
      btn.textContent = 'скопировано';
      setTimeout(function () { btn.textContent = old; }, 1800);
    });
  });
});
