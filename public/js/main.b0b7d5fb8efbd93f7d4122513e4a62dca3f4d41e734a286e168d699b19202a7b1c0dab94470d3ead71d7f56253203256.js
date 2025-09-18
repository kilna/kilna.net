document.addEventListener('click', (e) => {
  const link = e.target.closest('a.social-button.discord');
  if (!link) return;
  e.preventDefault();
  const username = 'kilna';
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(username).then(() => {
      alert(`Discord username copied: ${username}`);
    }).catch(() => {
      alert(`Discord username: ${username}`);
    });
  } else {
    alert(`Discord username: ${username}`);
  }
});


