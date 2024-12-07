const espIp = "192.168.1.77"; // Zaktualizuj IP

document.addEventListener('DOMContentLoaded', () => {
  const tabs = document.querySelectorAll('.tab-button');
  const tabContents = document.querySelectorAll('.tab-content');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const target = tab.getAttribute('data-tab');
      tabContents.forEach(tc => {
        tc.style.display = (tc.id === target) ? 'block' : 'none';
      });
    });
  });

  // Generowanie pomieszczeń
  const roomsContainer = document.getElementById('roomsContainer');
  const roomCount = 5;
  let roomsCct = [3000,4000,5000,6000,7000];
  let roomsBright = [50,50,50,50,50];

  for (let i = 0; i < roomCount; i++) {
    const card = document.createElement('div');
    card.className = 'card';

    const title = document.createElement('h2');
    title.textContent = `Pomieszczenie ${i+1}`;
    card.appendChild(title);

    const cctLabel = document.createElement('label');
    cctLabel.innerHTML = `Temperatura barwy (K): <span id="cctVal${i}">${roomsCct[i]}</span>`;
    card.appendChild(cctLabel);
    card.appendChild(document.createElement('br'));

    const cctRange = document.createElement('input');
    cctRange.type = 'range';
    cctRange.min = 2300;
    cctRange.max = 7500;
    cctRange.value = roomsCct[i];
    cctRange.addEventListener('input', () => {
      roomsCct[i] = cctRange.value;
      document.getElementById(`cctVal${i}`).textContent = cctRange.value;
      setRoom(i, cctRange.value, roomsBright[i]);
    });
    card.appendChild(cctRange);

    card.appendChild(document.createElement('br'));
    card.appendChild(document.createElement('br'));

    const brightLabel = document.createElement('label');
    brightLabel.innerHTML = `Jasność (%): <span id="brightVal${i}">${roomsBright[i]}</span>`;
    card.appendChild(brightLabel);
    card.appendChild(document.createElement('br'));

    const brightRange = document.createElement('input');
    brightRange.type = 'range';
    brightRange.min = 0;
    brightRange.max = 100;
    brightRange.value = roomsBright[i];
    brightRange.addEventListener('input', () => {
      roomsBright[i] = brightRange.value;
      document.getElementById(`brightVal${i}`).textContent = brightRange.value;
      setRoom(i, roomsCct[i], brightRange.value);
    });
    card.appendChild(brightRange);

    roomsContainer.appendChild(card);
  }

  // Budynek
  const buildingCctRange = document.getElementById('buildingCctRange');
  const buildingBrightRange = document.getElementById('buildingBrightRange');
  const buildingCctVal = document.getElementById('buildingCctVal');
  const buildingBrightVal = document.getElementById('buildingBrightVal');
  
  buildingCctRange.addEventListener('input', () => {
    buildingCctVal.textContent = buildingCctRange.value;
    setBuilding(buildingCctRange.value, buildingBrightRange.value);
  });

  buildingBrightRange.addEventListener('input', () => {
    buildingBrightVal.textContent = buildingBrightRange.value;
    setBuilding(buildingCctRange.value, buildingBrightRange.value);
  });

  const alarmBtn = document.getElementById('alarmBtn');
  const evacBtn = document.getElementById('evacBtn');
  alarmBtn.addEventListener('click', setAlarm);
  evacBtn.addEventListener('click', setEvacuation);

  const result = document.getElementById('result');

  async function setRoom(room, cct, brightness) {
    const url = `http://${espIp}/set?room=${room}&cct=${cct}&brightness=${brightness}`;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        const text = await response.text();
        result.textContent = "Błąd: " + text;
      } else {
        result.textContent = "";
      }
    } catch(e) {
      result.textContent = "Błąd połączenia: " + e;
    }
  }

  async function setBuilding(cct, brightness) {
    const url = `http://${espIp}/setBuilding?cct=${cct}&brightness=${brightness}`;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        const text = await response.text();
        result.textContent = "Błąd: " + text;
      } else {
        result.textContent = "";
      }
    } catch(e) {
      result.textContent = "Błąd połączenia: " + e;
    }
  }

  async function setAlarm() {
    const url = `http://${espIp}/alarm`;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        const text = await response.text();
        result.textContent = "Błąd: " + text;
      } else {
        result.textContent = "Alarm włączony";
      }
    } catch(e) {
      result.textContent = "Błąd połączenia: " + e;
    }
  }

  async function setEvacuation() {
    const url = `http://${espIp}/evacuation`;
    try {
      const response = await fetch(url);
      if (!response.ok) {
        const text = await response.text();
        result.textContent = "Błąd: " + text;
      } else {
        result.textContent = "Ewakuacja włączona";
      }
    } catch(e) {
      result.textContent = "Błąd połączenia: " + e;
    }
  }

});