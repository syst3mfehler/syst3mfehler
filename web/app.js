window.phx = (() => {
  const tabsEl = document.getElementById('tabs');
  const buttonsEl = document.getElementById('buttons');
  const counterEl = document.getElementById('counter');
  const descEl = document.getElementById('description');
  const thumbEl = document.getElementById('sidebarThumb');
  const keybindsEl = document.getElementById('keybinds');
  const spectatorsEl = document.getElementById('spectators');

  let state = {
    open: false,
    tabs: [ { name: 'List' }, { name: 'Safe' }, { name: 'Risky' }, { name: 'Vehicle' }, { name: 'Triggers' } ],
    activeTab: 0,
    items: [],
    index: 0,
    description: '',
    keybinds: [ ['Freeroam','OFF','Keybinds'], ['Noclip','CAPS',''] ],
    spectators: []
  };

  function renderTabs() {
    tabsEl.innerHTML = '';
    state.tabs.forEach((t, i) => {
      const el = document.createElement('div');
      el.className = 'tab' + (i === state.activeTab ? ' active' : '');
      el.textContent = t.name;
      tabsEl.appendChild(el);
    });
  }

  function renderButtons() {
    buttonsEl.innerHTML = '';
    state.items.forEach((it, i) => {
      const el = document.createElement('div');
      el.className = 'btn' + (i === state.index ? ' selected' : '');
      const name = document.createElement('div');
      name.textContent = it.label;
      const right = document.createElement('div');
      if (it.toggle !== undefined) {
        const t = document.createElement('div');
        t.className = 'toggle' + (it.toggle ? '' : '');
        const dot = document.createElement('div');
        dot.className = 'dot';
        t.appendChild(dot);
        if (it.toggle) el.classList.add('active');
        right.appendChild(t);
      } else if (it.value !== undefined) {
        const span = document.createElement('span');
        span.className = 'val';
        span.textContent = String(it.value);
        right.appendChild(span);
      }
      el.appendChild(name);
      el.appendChild(right);
      buttonsEl.appendChild(el);
    });
    counterEl.textContent = `${state.index + 1}/${state.items.length}`;
    descEl.textContent = state.items[state.index]?.description || '';

    const total = Math.max(state.items.length, 1);
    const track = 429 - 34; // sidebar height - thumb
    const y = total <= 1 ? 0 : Math.round((state.index / (total - 1)) * track);
    thumbEl.style.transform = `translateY(${y}px)`;
  }

  function renderKeyPanels() {
    keybindsEl.innerHTML = '';
    state.keybinds.forEach(([key, val]) => {
      const k = document.createElement('div');
      k.className = 'key';
      k.textContent = val;
      const v = document.createElement('div');
      v.className = 'val';
      v.textContent = key;
      keybindsEl.appendChild(k);
      keybindsEl.appendChild(v);
    });

    spectatorsEl.innerHTML = '';
    if (state.spectators.length === 0) {
      const v = document.createElement('div');
      v.className = 'val';
      v.textContent = '0 spectators';
      spectatorsEl.appendChild(v);
    } else {
      state.spectators.forEach((s) => {
        const v = document.createElement('div');
        v.className = 'val';
        v.textContent = s;
        spectatorsEl.appendChild(v);
      });
    }
  }

  function render() {
    renderTabs();
    renderButtons();
    renderKeyPanels();
  }

  function renderState(next) {
    state = Object.assign({}, state, next);
    render();
  }

  return { renderState };
})();

