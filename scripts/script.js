const button = document.getElementById('startBtn');
const overlay = document.getElementById('overlay');
const screamAudio = document.getElementById("screamAudio");

button.addEventListener('click', () => {
  overlay.style.display = 'flex';
  screamAudio.play();
  setTimeout(() => {
    overlay.style.display = 'none';
  }, 4000); // Desaparece después de 2 segundos
});
