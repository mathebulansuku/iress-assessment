(() => {
  const $ = (s) => document.querySelector(s);
  const statusEl = $('#status');
  const listEl = $('#list');
  const inputEl = $('#apiUrl');
  const btnEl = $('#loadBtn');

  const prefillUrl = (window.CONFIG && window.CONFIG.API_URL) || '';
  if (prefillUrl) inputEl.value = prefillUrl;

  function setStatus(msg, isError=false) {
    statusEl.textContent = msg || '';
    statusEl.classList.toggle('hidden', !msg);
    statusEl.classList.toggle('error', !!isError);
  }

  function formatNumber(n) {
    try { return new Intl.NumberFormat().format(n); } catch { return String(n); }
  }

  function render(countries) {
    listEl.innerHTML = '';
    countries.forEach((c) => {
      const li = document.createElement('li');
      li.innerHTML = `
        <div class="name">${c.country}</div>
        <div class="pop">Total population: ${formatNumber(c.total_population)}</div>
      `;
      listEl.appendChild(li);
    });
  }

  async function load() {
    const base = inputEl.value.trim().replace(/\/$/, '');
    if (!base) {
      setStatus('Please enter your API base URL (e.g., https://...execute-api.../ or .../$default).', true);
      return;
    }
    setStatus('Loading…');
    listEl.innerHTML = '';
    try {
      const res = await fetch(`${base}/hello`, { method: 'GET' });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();
      const countries = data?.top_countries || [];
      if (!Array.isArray(countries) || countries.length === 0) {
        setStatus('No data returned from API.');
        return;
      }
      setStatus('');
      render(countries);
    } catch (err) {
      setStatus(`Failed to load: ${err.message}. If running from a file or different domain, ensure CORS is enabled on the API.`, true);
    }
  }

  btnEl.addEventListener('click', load);
  inputEl.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });

  // Auto-load if prefilled
  if (prefillUrl) load();
})();

