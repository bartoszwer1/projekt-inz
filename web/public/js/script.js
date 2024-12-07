const espIp = "192.168.1.77";

  const cctRange = document.getElementById('cctRange');
  const brightRange = document.getElementById('brightRange');
  const cctVal = document.getElementById('cctVal');
  const brightVal = document.getElementById('brightVal');
  const roomSelect = document.getElementById('roomSelect');
  const result = document.getElementById('result');
  const applyBtn = document.getElementById('applyBtn');

  cctRange.addEventListener('input', () => {
    cctVal.textContent = cctRange.value;
  });

  brightRange.addEventListener('input', () => {
    brightVal.textContent = brightRange.value;
  });

  applyBtn.addEventListener('click', async () => {
    const room = roomSelect.value;
    const cct = cctRange.value;
    const brightness = brightRange.value;

    const url = `http://${espIp}/set?room=${room}&cct=${cct}&brightness=${brightness}`;
    try {
      const response = await fetch(url);
      if (response.ok) {
        result.textContent = "Zmieniono parametry!";
      } else {
        const text = await response.text();
        result.textContent = "Błąd: " + text;
      }
    } catch(e) {
      result.textContent = "Błąd połączenia: " + e;
    }
  });