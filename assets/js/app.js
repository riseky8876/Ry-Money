import * as S from './store.js'
import * as F from './format.js'

const app = document.getElementById('app')
const sheet = document.getElementById('sheet')
const toastEl = document.getElementById('toast')

const state = S.loadState()
const native = window.RyNative || null
let route = 'ringkas'
let animatedKey = ''
let sheetSubmit = null

const views = { ringkas: viewRingkas, gaji: viewGaji, tabungan: viewTabungan, catatan: viewCatatan }

/* ---------- kerangka ---------- */

function persist() {
  if (!S.saveState(state)) toast('Gagal menyimpan. Penyimpanan perangkat penuh?')
}

let toastTimer
function toast(msg) {
  toastEl.textContent = msg
  toastEl.classList.add('is-on')
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => toastEl.classList.remove('is-on'), 2800)
}

function setRoute() {
  const r = location.hash.replace(/^#\/?/, '')
  route = views[r] ? r : 'ringkas'
  render()
}

function render() {
  document.getElementById('month-label').textContent = F.monthLabel(state.month)
  document.querySelectorAll('.tab').forEach((a) => {
    const on = a.dataset.route === route
    a.classList.toggle('is-active', on)
    if (on) a.setAttribute('aria-current', 'page')
    else a.removeAttribute('aria-current')
  })
  try {
    app.innerHTML = views[route]()
  } catch (err) {
    console.error(err)
    app.innerHTML = `<div class="empty"><h3>Ada yang gagal digambar.</h3><p>${F.esc(err.message)}</p><button type="button" class="btn btn-ghost" data-act="goto" data-goto="ringkas">Kembali</button></div>`
    return
  }
  attachMoney(app)
  wireSalaryForm()
  fitFigures()
  animateBalance()
}

// Angka rupiah panjang tidak boleh pecah baris: kecilkan font sampai pas.
function fitFigures() {
  document.querySelectorAll('.balance-figure').forEach((el) => {
    el.style.fontSize = ''
    const avail = el.parentElement?.clientWidth || 0
    if (!avail) return
    let size = parseFloat(window.getComputedStyle(el).fontSize) || 48
    let guard = 0
    while (el.scrollWidth > avail && size > 24 && guard++ < 40) {
      size -= 2
      el.style.fontSize = `${size}px`
    }
  })
}

/* ---------- input nominal ---------- */

function attachMoney(root) {
  root.querySelectorAll('[data-money]').forEach((el) => {
    el.addEventListener('input', () => {
      const n = F.parseRp(el.value)
      el.value = n ? F.fmtNum(n) : ''
    })
  })
}

/* ---------- sheet / dialog ---------- */

function openSheet({ title, sub = '', body, submit = 'Simpan', danger = false, onSubmit }) {
  sheet.innerHTML = `
    <form class="sheet-form" novalidate>
      <div class="sheet-head">
        <h2 class="sheet-title" id="sheet-title">${title}</h2>
        <button type="button" class="icon-btn" data-close aria-label="Tutup">✕</button>
      </div>
      ${sub ? `<p class="sheet-sub">${sub}</p>` : ''}
      <div class="sheet-body">${body}</div>
      <p class="form-error" data-error hidden></p>
      <div class="sheet-actions">
        <button type="button" class="btn btn-ghost" data-close>Batal</button>
        <button type="submit" class="btn ${danger ? 'btn-danger' : 'btn-primary'}">${submit}</button>
      </div>
    </form>`
  sheetSubmit = onSubmit
  prepareSheet()
  sheet.showModal()
  sheet.querySelector('input:not([type=hidden]), select')?.focus()
}

function openPanel({ title, sub = '', body, after }) {
  sheet.innerHTML = `
    <div class="sheet-form">
      <div class="sheet-head">
        <h2 class="sheet-title" id="sheet-title">${title}</h2>
        <button type="button" class="icon-btn" data-close aria-label="Tutup">✕</button>
      </div>
      ${sub ? `<p class="sheet-sub">${sub}</p>` : ''}
      <div class="sheet-body">${body}</div>
    </div>`
  sheetSubmit = null
  prepareSheet()
  sheet.showModal()
  after?.(sheet)
}

function prepareSheet() {
  attachMoney(sheet)
  sheet.querySelectorAll('[data-close]').forEach((b) => b.addEventListener('click', () => sheet.close()))
  sheet.querySelectorAll('.segmented [data-seg]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const group = btn.closest('.segmented')
      group.querySelectorAll('[data-seg]').forEach((b) => b.classList.toggle('is-active', b === btn))
      const hidden = group.querySelector('input[type="hidden"]')
      if (hidden) hidden.value = btn.dataset.seg
    })
  })
  sheet.querySelectorAll('[data-fill]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const input = sheet.querySelector('[name="amount"]')
      if (!input) return
      input.value = F.fmtNum(Number(btn.dataset.fill) || 0)
      input.dispatchEvent(new Event('input'))
    })
  })
}

sheet.addEventListener('submit', (e) => {
  e.preventDefault()
  const errEl = sheet.querySelector('[data-error]')
  const fail = (msg) => {
    if (errEl) {
      errEl.textContent = msg
      errEl.hidden = false
    }
    return false
  }
  if (errEl) errEl.hidden = true
  if (!sheetSubmit) return
  if (sheetSubmit(new FormData(e.target), fail)) sheet.close()
})

sheet.addEventListener('click', (e) => {
  if (e.target === sheet) sheet.close()
})

/* ---------- aksi global ---------- */

document.addEventListener('click', (e) => {
  const el = e.target.closest('[data-act]')
  if (!el) return
  const act = el.dataset.act
  const id = el.dataset.id

  if (act === 'month-prev' || act === 'month-next') {
    state.month = F.shiftMonth(state.month, act === 'month-prev' ? -1 : 1)
    persist()
    render()
    return
  }
  if (act === 'goto') {
    location.hash = '#/' + el.dataset.goto
    return
  }
  if (act === 'open-settings') return settingsSheet()
  if (act === 'add-routine') return routineSheet()
  if (act === 'add-goal') return goalSheet()
  if (act === 'add-txn') return txnSheet()

  if (act === 'toggle-routine') {
    const r = state.routines.find((x) => x.id === id)
    if (!r) return
    r.active = !r.active
    persist()
    render()
    return
  }
  if (act === 'edit-routine') {
    const r = state.routines.find((x) => x.id === id)
    if (r) routineSheet(r)
    return
  }
  if (act === 'del-routine') {
    const r = state.routines.find((x) => x.id === id)
    if (!r) return
    if (!confirm(`Hapus rutinitas "${r.name}"? Gaji yang sudah tercatat tidak berubah.`)) return
    state.routines = state.routines.filter((x) => x.id !== id)
    persist()
    render()
    toast('Rutinitas dihapus.')
    return
  }
  if (act === 'edit-goal') {
    const g = state.goals.find((x) => x.id === id)
    if (g) goalSheet(g)
    return
  }
  if (act === 'deposit') {
    const g = state.goals.find((x) => x.id === id)
    if (g) depositSheet(g)
    return
  }
  if (act === 'del-goal') {
    const g = state.goals.find((x) => x.id === id)
    if (!g) return
    if (!confirm(`Hapus target "${g.name}" beserta riwayat setorannya?`)) return
    state.goals = state.goals.filter((x) => x.id !== id)
    persist()
    render()
    toast('Target dihapus.')
    return
  }
  if (act === 'del-income') {
    if (!confirm('Hapus catatan gaji ini? Penyisihannya ikut hilang.')) return
    state.incomes = state.incomes.filter((x) => x.id !== id)
    persist()
    render()
    toast('Catatan gaji dihapus.')
    return
  }
  if (act === 'del-txn') {
    if (!confirm('Hapus catatan ini?')) return
    state.txns = state.txns.filter((x) => x.id !== id)
    persist()
    render()
    toast('Catatan dihapus.')
    return
  }
  if (act === 'export') return exportData()
  if (act === 'import-native') {
    if (native?.pickBackup) native.pickBackup()
    return
  }
  if (act === 'reset') {
    if (!confirm('Hapus SEMUA data di perangkat ini? Tindakan ini tidak bisa dibatalkan.')) return
    Object.assign(state, S.defaultState())
    persist()
    sheet.close()
    render()
    toast('Semua data dihapus.')
    return
  }
})

window.addEventListener('hashchange', setRoute)

/* ---------- tampilan: ringkasan ---------- */

function viewRingkas() {
  const m = state.month
  const t = S.monthTotals(state, m)
  const active = state.routines.filter((r) => r.active)
  const planned = S.plannedMonthly(active)
  const inflow = t.income + t.extra
  const over = t.available < 0
  const pct = (v) => (inflow > 0 ? Math.max(0, Math.min(100, (v / inflow) * 100)) : 0)
  const whole = inflow > 0 ? Math.round((Math.max(0, t.available) / inflow) * 100) : 0
  const hasData = state.incomes.length || state.txns.length || state.routines.length || state.goals.length

  const recent = state.txns
    .filter((x) => x.date.slice(0, 7) === m)
    .sort((a, b) => b.date.localeCompare(a.date) || (b.createdAt || 0) - (a.createdAt || 0))
    .slice(0, 4)

  const goals = state.goals
    .filter((g) => !S.goalEta(g).done)
    .sort((a, b) => (S.goalEta(a).days ?? 1e9) - (S.goalEta(b).days ?? 1e9))
    .slice(0, 2)

  const bar = inflow > 0
    ? `<div class="splitbar" role="img" aria-label="Penyisihan ${F.fmtRp(t.allocated)}, tabungan ${F.fmtRp(t.saved)}, pengeluaran ${F.fmtRp(t.spent)}, sisa ${F.fmtRp(t.available)}">
        <i class="s-alloc" style="width:${pct(t.allocated)}%"></i>
        <i class="s-save" style="width:${pct(t.saved)}%"></i>
        <i class="s-spend" style="width:${pct(t.spent)}%"></i>
        <i class="s-rest" style="width:${pct(Math.max(0, t.available))}%"></i>
      </div>
      <ul class="split-legend">
        <li><span class="sw s-alloc"></span>Penyisihan ${Math.round(pct(t.allocated))}%</li>
        <li><span class="sw s-save"></span>Tabungan ${Math.round(pct(t.saved))}%</li>
        <li><span class="sw s-spend"></span>Belanja ${Math.round(pct(t.spent))}%</li>
        <li><span class="sw s-rest"></span>Sisa ${Math.round(pct(Math.max(0, t.available)))}%</li>
      </ul>`
    : `<div class="splitbar is-empty" aria-hidden="true"><i></i></div>
      <p class="hint" style="margin-top:10px">Belum ada pemasukan bulan ini.</p>`

  return `
  <header class="view-head">
    <p class="eyebrow">Buku kas · ${F.esc(F.monthLabel(m))}</p>
    <h1 class="h1">Uangmu,<br>dalam satu garis.</h1>
  </header>

  <section class="balance">
    ${inflow > 0 ? `<span class="stamp">${whole}% utuh</span>` : ''}
    <p class="eyebrow">Sisa bisa dipakai</p>
    <p class="balance-figure ${over ? 'is-neg' : ''}" data-count="${t.available}">${F.fmtRp(t.available)}</p>
    <p class="balance-note">${
      inflow === 0
        ? 'Catat gaji dulu supaya angka ini hidup.'
        : over
          ? 'Pengeluaran melebihi pemasukan bulan ini.'
          : `dari ${F.fmtRp(inflow)} yang masuk bulan ini.`
    }</p>
    ${bar}
  </section>

  <div class="ledger">
    ${ledgerRow('Gaji masuk', F.fmtRp(t.income))}
    ${t.extra ? ledgerRow('Pemasukan lain', F.fmtRp(t.extra)) : ''}
    ${ledgerRow('Penyisihan rutin', '−' + F.fmtRp(t.allocated))}
    ${ledgerRow('Setor tabungan', '−' + F.fmtRp(t.saved))}
    ${ledgerRow('Pengeluaran', '−' + F.fmtRp(t.spent))}
    <div class="ledger-row is-total">
      <span class="k">Sisa</span><span class="leader"></span>
      <span class="v ${over ? 'is-neg' : ''}">${F.fmtRp(t.available)}</span>
    </div>
  </div>

  ${!hasData ? startBlock() : ''}

  ${active.length ? `
  <section class="section">
    <div class="section-head">
      <h2 class="h2">Penyisihan</h2>
      <a class="link" href="#/gaji">Kelola</a>
    </div>
    <p class="hint">${F.fmtRp(planned)} per bulan dari ${active.length} rutinitas aktif.</p>
    <div class="rows">
      ${active.slice(0, 4).map((r) => `
        <div class="row">
          <div class="row-main">
            <p class="row-title">${F.esc(r.name)}</p>
            <p class="row-sub">${F.fmtRp(r.amount)} ${S.CYCLE_LABEL[r.cycle]}</p>
          </div>
          <span class="amt">${F.fmtRp(S.routineMonthly(r))}</span>
        </div>`).join('')}
    </div>
  </section>` : ''}

  ${goals.length ? `
  <section class="section">
    <div class="section-head">
      <h2 class="h2">Dikejar</h2>
      <a class="link" href="#/tabungan">Semua target</a>
    </div>
    ${goals.map((g) => {
      const eta = S.goalEta(g)
      const p = g.target > 0 ? Math.min(100, Math.round((eta.saved / g.target) * 100)) : 0
      return `<div class="goal">
        <div class="goal-top"><h3 class="goal-name">${F.esc(g.name)}</h3><span class="goal-pct">${p}%</span></div>
        <div class="bar"><i style="width:${p}%"></i></div>
        <p class="goal-meta"><span>${F.fmtRp(eta.saved)} / ${F.fmtRp(g.target)}</span><span>${F.etaLabel(eta.days)}</span></p>
      </div>`
    }).join('')}
  </section>` : ''}

  ${recent.length ? `
  <section class="section">
    <div class="section-head">
      <h2 class="h2">Terakhir</h2>
      <a class="link" href="#/catatan">Semua catatan</a>
    </div>
    <div class="rows">
      ${recent.map((x) => txnRow(x)).join('')}
    </div>
  </section>` : ''}

  <p class="footnote">Data tersimpan di HP ini. Unduh cadangan dari tombol ⚙ di atas.</p>
  `
}

function ledgerRow(k, v, cls = '') {
  return `<div class="ledger-row"><span class="k">${k}</span><span class="leader"></span><span class="v ${cls}">${v}</span></div>`
}

function txnRow(t) {
  const out = t.type !== 'masuk'
  return `<div class="row">
    <div class="row-main">
      <p class="row-title">${F.esc(t.note || t.category || 'Tanpa keterangan')}</p>
      <p class="row-sub">${F.esc(t.category || 'Lainnya')} · ${F.fmtDate(t.date)}</p>
    </div>
    <span class="amt ${out ? 'is-out' : 'is-in'}">${out ? '−' : '+'}${F.fmtRp(t.amount)}</span>
  </div>`
}

function startBlock() {
  return `<section class="start">
    <p class="eyebrow">Mulai dari sini</p>
    <h2 class="start-title">Tiga langkah, lalu tinggal pakai.</h2>
    <p class="lede">Sekitar dua menit. Tidak ada akun, tidak ada server.</p>
    <ol class="start-list">
      <li><span class="n">01</span><div><b>Catat gaji</b><p>Nominal yang benar-benar masuk.</p></div><button type="button" class="btn btn-primary btn-sm" data-act="goto" data-goto="gaji">Catat</button></li>
      <li><span class="n">02</span><div><b>Isi rutinitas</b><p>Kos, bensin, listrik — dipotong otomatis.</p></div><button type="button" class="btn btn-ghost btn-sm" data-act="add-routine">Tambah</button></li>
      <li><span class="n">03</span><div><b>Pasang target</b><p>Barang yang mau dibeli, dengan ritme menabung.</p></div><button type="button" class="btn btn-ghost btn-sm" data-act="add-goal">Buat</button></li>
    </ol>
  </section>`
}

/* ---------- tampilan: gaji ---------- */

function viewGaji() {
  const m = state.month
  const active = state.routines.filter((r) => r.active)
  const planned = S.plannedMonthly(active)
  const incomes = state.incomes
    .filter((i) => i.date.slice(0, 7) === m)
    .sort((a, b) => b.date.localeCompare(a.date))
  const monthIncome = incomes.reduce((s, i) => s + i.amount, 0)

  return `
  <header class="view-head">
    <p class="eyebrow">Pemasukan</p>
    <h1 class="h1">Gaji &amp; penyisihan</h1>
    <p class="lede">Catat gaji yang masuk. Rutinitas aktif langsung dipotong dari angka itu.</p>
  </header>

  <section class="panel">
    <form id="salary-form" class="form" novalidate>
      <div class="field">
        <label for="salary-amount">Nominal gaji</label>
        <div class="money-wrap"><span class="prefix">Rp</span>
          <input id="salary-amount" name="amount" data-money inputmode="numeric" placeholder="0" required autocomplete="off">
        </div>
      </div>
      <div class="field-row">
        <div class="field">
          <label for="salary-date">Tanggal masuk</label>
          <input type="date" id="salary-date" name="date" value="${F.todayISO()}">
        </div>
        <div class="field">
          <label for="salary-label">Keterangan</label>
          <input id="salary-label" name="label" placeholder="Gaji ${F.esc(F.monthLabel(m))}" maxlength="60" autocomplete="off">
        </div>
      </div>
      <label class="check">
        <input type="checkbox" name="auto" ${active.length ? 'checked' : 'disabled'}>
        <span>Potong penyisihan otomatis${active.length ? ` (${active.length} rutinitas)` : ''}</span>
      </label>
      <div class="preview" id="salary-preview" aria-live="polite"></div>
      <button class="btn btn-primary btn-block" type="submit">Simpan gaji</button>
    </form>
  </section>

  <section class="section">
    <div class="section-head">
      <h2 class="h2">Rutinitas</h2>
      <button type="button" class="link" data-act="add-routine">+ Tambah</button>
    </div>
    <p class="hint">Total ${F.fmtRp(planned)} per bulan${active.length ? ` · ${active.length} aktif` : ''}. Hitungan: harian ×30, mingguan ×4,3, bulanan ×1.</p>
    <div class="rows">
      ${state.routines.length
        ? state.routines.map((r) => `
          <div class="row ${r.active ? '' : 'is-off'}">
            <div class="row-main">
              <p class="row-title">${F.esc(r.name)}</p>
              <p class="row-sub">${F.fmtRp(r.amount)} ${S.CYCLE_LABEL[r.cycle]} · ${F.fmtRp(S.routineMonthly(r))}/bln</p>
            </div>
            <button type="button" class="switch" role="switch" aria-checked="${!!r.active}" aria-label="Aktifkan ${F.esc(r.name)}" data-act="toggle-routine" data-id="${r.id}"></button>
            <button type="button" class="icon-btn" data-act="edit-routine" data-id="${r.id}" aria-label="Ubah ${F.esc(r.name)}">✎</button>
            <button type="button" class="icon-btn" data-act="del-routine" data-id="${r.id}" aria-label="Hapus ${F.esc(r.name)}">✕</button>
          </div>`).join('')
        : `<p class="empty-line">Belum ada rutinitas. Tambahkan kos, transport, listrik — apa pun yang berulang.</p>`}
    </div>
  </section>

  <section class="section">
    <div class="section-head">
      <h2 class="h2">Gaji bulan ini</h2>
      <span class="hint">${F.fmtRp(monthIncome)}</span>
    </div>
    <div class="rows">
      ${incomes.length
        ? incomes.map((i) => `
          <div class="row">
            <div class="row-main">
              <p class="row-title">${F.esc(i.label || 'Gaji')}</p>
              <p class="row-sub">${F.fmtDate(i.date)} · disisihkan ${F.fmtRp((i.allocations || []).reduce((s, a) => s + a.amount, 0))}</p>
            </div>
            <span class="amt">${F.fmtRp(i.amount)}</span>
            <button type="button" class="icon-btn" data-act="del-income" data-id="${i.id}" aria-label="Hapus catatan gaji">✕</button>
          </div>`).join('')
        : `<p class="empty-line">Belum ada gaji tercatat bulan ini.</p>`}
    </div>
  </section>`
}

function wireSalaryForm() {
  const form = document.getElementById('salary-form')
  if (!form) return
  form.addEventListener('submit', onSalarySubmit)
  const amount = form.querySelector('[name="amount"]')
  const auto = form.querySelector('[name="auto"]')
  amount.addEventListener('input', renderSalaryPreview)
  auto.addEventListener('change', renderSalaryPreview)
  renderSalaryPreview()
}

function renderSalaryPreview() {
  const box = document.getElementById('salary-preview')
  const form = document.getElementById('salary-form')
  if (!box || !form) return
  const amount = F.parseRp(form.querySelector('[name="amount"]').value)
  const autoBox = form.querySelector('[name="auto"]')
  const auto = autoBox.checked && !autoBox.disabled
  const active = state.routines.filter((r) => r.active)
  if (!active.length) {
    box.innerHTML = `<p class="preview-note">Belum ada rutinitas aktif. Gaji akan dicatat utuh.</p>`
    return
  }
  const cut = auto ? S.plannedMonthly(active) : 0
  box.innerHTML = `
    <div class="ledger">
      <div class="ledger-row"><span class="k">Gaji</span><span class="leader"></span><span class="v">${F.fmtRp(amount)}</span></div>
      ${auto ? active.map((r) => `<div class="ledger-row is-sub"><span class="k">${F.esc(r.name)}</span><span class="leader"></span><span class="v">−${F.fmtRp(S.routineMonthly(r))}</span></div>`).join('') : ''}
      <div class="ledger-row is-total"><span class="k">Sisa setelah penyisihan</span><span class="leader"></span><span class="v ${amount - cut < 0 ? 'is-neg' : ''}">${F.fmtRp(amount - cut)}</span></div>
    </div>
    ${amount && cut > amount ? `<p class="preview-warn">Penyisihan lebih besar dari gaji. Kecilkan nominal rutinitas, atau matikan potong otomatis.</p>` : ''}`
}

function onSalarySubmit(e) {
  e.preventDefault()
  const form = e.target
  const fd = new FormData(form)
  const amount = F.parseRp(fd.get('amount'))
  if (amount <= 0) {
    toast('Isi nominal gaji dulu.')
    form.querySelector('[name="amount"]').focus()
    return
  }
  const date = String(fd.get('date') || F.todayISO())
  const auto = fd.get('auto') === 'on'
  const allocations = auto
    ? state.routines.filter((r) => r.active).map((r) => ({ routineId: r.id, name: r.name, amount: S.routineMonthly(r) }))
    : []
  state.incomes.push({
    id: S.uid(),
    date,
    label: String(fd.get('label') || '').trim() || 'Gaji',
    amount,
    allocations,
    createdAt: Date.now(),
  })
  state.month = date.slice(0, 7)
  persist()
  render()
  const cut = allocations.reduce((s, a) => s + a.amount, 0)
  toast(cut ? `Gaji dicatat. ${F.fmtRp(cut)} disisihkan.` : 'Gaji dicatat.')
}

/* ---------- sheet: rutinitas ---------- */

function routineSheet(routine) {
  const r = routine || { name: '', amount: 0, cycle: 'bulanan' }
  const opts = Object.entries(S.CYCLE_LABEL)
    .map(([k, label]) => `<option value="${k}" ${r.cycle === k ? 'selected' : ''}>${k} (${label})</option>`)
    .join('')

  openSheet({
    title: routine ? 'Ubah rutinitas' : 'Rutinitas baru',
    sub: 'Penyisihan dihitung per bulan: harian ×30, mingguan ×4,3, bulanan ×1.',
    body: `
      <div class="field">
        <label for="r-name">Nama</label>
        <input id="r-name" name="name" value="${F.esc(r.name)}" placeholder="Kos, bensin, listrik…" required maxlength="60" autocomplete="off">
      </div>
      <div class="field">
        <label for="r-amount">Nominal sekali bayar</label>
        <div class="money-wrap"><span class="prefix">Rp</span>
          <input id="r-amount" name="amount" data-money inputmode="numeric" value="${r.amount ? F.fmtNum(r.amount) : ''}" required autocomplete="off">
        </div>
      </div>
      <div class="field">
        <label for="r-cycle">Siklus</label>
        <select id="r-cycle" name="cycle">${opts}</select>
      </div>`,
    onSubmit: (fd, fail) => {
      const name = String(fd.get('name') || '').trim()
      const amount = F.parseRp(fd.get('amount'))
      const cycle = String(fd.get('cycle') || 'bulanan')
      if (!name) return fail('Nama rutinitas belum diisi.')
      if (amount <= 0) return fail('Nominal harus lebih dari nol.')
      if (routine) Object.assign(routine, { name, amount, cycle })
      else state.routines.push({ id: S.uid(), name, amount, cycle, active: true })
      persist()
      render()
      toast(routine ? 'Rutinitas diperbarui.' : 'Rutinitas ditambahkan.')
      return true
    },
  })
}

/* ---------- tampilan: tabungan ---------- */

function viewTabungan() {
  const goals = state.goals.slice().sort((a, b) => {
    const da = S.goalEta(a)
    const db = S.goalEta(b)
    if (da.done !== db.done) return da.done ? 1 : -1
    return (da.days ?? 1e9) - (db.days ?? 1e9)
  })
  const totalTarget = goals.reduce((s, g) => s + (Number(g.target) || 0), 0)
  const totalSaved = goals.reduce((s, g) => s + S.goalSaved(g), 0)
  const overall = totalTarget > 0 ? Math.min(100, Math.round((totalSaved / totalTarget) * 100)) : 0

  return `
  <header class="view-head">
    <p class="eyebrow">Tabungan</p>
    <h1 class="h1">Target &amp; wishlist</h1>
    <p class="lede">Tulis barangnya, tentukan ritme menabung, biarkan sisanya dihitung.</p>
  </header>

  <section class="balance">
    <p class="eyebrow">Terkumpul untuk semua target</p>
    <p class="balance-figure" data-count="${totalSaved}">${F.fmtRp(totalSaved)}</p>
    <p class="balance-note">${totalTarget > 0 ? `dari ${F.fmtRp(totalTarget)} · ${overall}%` : 'Belum ada target.'}</p>
    <div class="bar"><i style="width:${overall}%"></i></div>
  </section>

  <div class="section-head" style="margin-top:26px">
    <h2 class="h2">Daftar target</h2>
    <button type="button" class="link" data-act="add-goal">+ Tambah</button>
  </div>

  ${goals.length ? goals.map(goalCard).join('') : `
    <div class="empty">
      <h3>Belum ada yang dikejar.</h3>
      <p>Mulai dari satu barang. Nominal dan ritmenya bebas — per hari, per minggu, atau per bulan.</p>
      <button type="button" class="btn btn-primary" data-act="add-goal">Buat target pertama</button>
    </div>`}`
}

function goalCard(g) {
  const eta = S.goalEta(g)
  const p = g.target > 0 ? Math.min(100, Math.round((eta.saved / g.target) * 100)) : 0
  return `<article class="goal ${eta.done ? 'is-done' : ''}">
    <div class="goal-top">
      <h3 class="goal-name">${F.esc(g.name)}</h3>
      ${eta.done ? '<span class="stamp">Tercapai</span>' : `<span class="goal-pct">${p}%</span>`}
    </div>
    <p class="goal-num"><span>${F.fmtRp(eta.saved)}</span> <em>/ ${F.fmtRp(g.target)}</em></p>
    <div class="bar"><i style="width:${p}%"></i></div>
    <div class="goal-meta">
      <span>Rencana ${F.fmtRp(g.planAmount)} ${S.PERIOD_LABEL[g.planPeriod] || ''}</span>
      <span>${eta.done ? 'target tercapai' : `${F.fmtRp(eta.remaining)} lagi · ${F.etaLabel(eta.days)}`}</span>
    </div>
    <div class="goal-actions">
      <button type="button" class="btn btn-primary btn-sm" data-act="deposit" data-id="${g.id}">Setor</button>
      <button type="button" class="btn btn-ghost btn-sm" data-act="edit-goal" data-id="${g.id}">Ubah</button>
      <button type="button" class="icon-btn" data-act="del-goal" data-id="${g.id}" aria-label="Hapus ${F.esc(g.name)}">✕</button>
    </div>
  </article>`
}

function goalSheet(goal) {
  const g = goal || { name: '', target: 0, planAmount: 0, planPeriod: 'minggu' }
  const opts = Object.entries(S.PERIOD_LABEL)
    .map(([k, label]) => `<option value="${k}" ${g.planPeriod === k ? 'selected' : ''}>${label}</option>`)
    .join('')

  openSheet({
    title: goal ? 'Ubah target' : 'Target baru',
    sub: 'Nominal bebas. Perkiraan waktu dihitung dari sisa target dibagi ritme menabung.',
    body: `
      <div class="field">
        <label for="g-name">Barang atau tujuan</label>
        <input id="g-name" name="name" value="${F.esc(g.name)}" placeholder="Sepatu, laptop, dana darurat…" required maxlength="60" autocomplete="off">
      </div>
      <div class="field">
        <label for="g-target">Harga / target</label>
        <div class="money-wrap"><span class="prefix">Rp</span>
          <input id="g-target" name="target" data-money inputmode="numeric" value="${g.target ? F.fmtNum(g.target) : ''}" required autocomplete="off">
        </div>
      </div>
      <div class="field-row">
        <div class="field">
          <label for="g-plan">Nabung</label>
          <div class="money-wrap"><span class="prefix">Rp</span>
            <input id="g-plan" name="planAmount" data-money inputmode="numeric" value="${g.planAmount ? F.fmtNum(g.planAmount) : ''}" required autocomplete="off">
          </div>
        </div>
        <div class="field">
          <label for="g-period">Ritme</label>
          <select id="g-period" name="planPeriod">${opts}</select>
        </div>
      </div>`,
    onSubmit: (fd, fail) => {
      const name = String(fd.get('name') || '').trim()
      const target = F.parseRp(fd.get('target'))
      const planAmount = F.parseRp(fd.get('planAmount'))
      const planPeriod = String(fd.get('planPeriod') || 'minggu')
      if (!name) return fail('Nama target belum diisi.')
      if (target <= 0) return fail('Harga target harus lebih dari nol.')
      if (planAmount <= 0) return fail('Nominal nabung harus lebih dari nol.')
      if (goal) Object.assign(goal, { name, target, planAmount, planPeriod })
      else state.goals.push({ id: S.uid(), name, target, planAmount, planPeriod, deposits: [] })
      persist()
      render()
      toast(goal ? 'Target diperbarui.' : 'Target dibuat.')
      return true
    },
  })
}

function depositSheet(goal) {
  const eta = S.goalEta(goal)
  const quick = [
    goal.planAmount ? `<button type="button" class="chip" data-fill="${goal.planAmount}">Sesuai rencana</button>` : '',
    goal.planAmount ? `<button type="button" class="chip" data-fill="${goal.planAmount * 2}">2× rencana</button>` : '',
    eta.remaining > 0 ? `<button type="button" class="chip" data-fill="${eta.remaining}">Sisa target</button>` : '',
  ].join('')

  openSheet({
    title: `Setor — ${F.esc(goal.name)}`,
    sub: `Sisa ${F.fmtRp(eta.remaining)} dari target ${F.fmtRp(goal.target)}.`,
    body: `
      <div class="field">
        <label for="d-amount">Nominal setoran</label>
        <div class="money-wrap"><span class="prefix">Rp</span>
          <input id="d-amount" name="amount" data-money inputmode="numeric" value="${goal.planAmount ? F.fmtNum(goal.planAmount) : ''}" required autocomplete="off">
        </div>
      </div>
      <div class="quick">${quick}</div>
      <div class="field">
        <label for="d-date">Tanggal</label>
        <input type="date" id="d-date" name="date" value="${F.todayISO()}">
      </div>`,
    onSubmit: (fd, fail) => {
      const amount = F.parseRp(fd.get('amount'))
      if (amount <= 0) return fail('Nominal setoran belum diisi.')
      const date = String(fd.get('date') || F.todayISO())
      goal.deposits = goal.deposits || []
      goal.deposits.push({ id: S.uid(), date, amount })
      persist()
      render()
      const after = S.goalEta(goal)
      toast(after.done ? `Target "${goal.name}" tercapai.` : `Disetor ${F.fmtRp(amount)}. Sisa ${F.fmtRp(after.remaining)}.`)
      return true
    },
  })
}

/* ---------- tampilan: catatan ---------- */

function viewCatatan() {
  const m = state.month
  const list = state.txns.filter((t) => t.date.slice(0, 7) === m)
  const groups = S.groupTxnsByDay(list)
  const spent = list.filter((t) => t.type !== 'masuk').reduce((s, t) => s + t.amount, 0)
  const masuk = list.filter((t) => t.type === 'masuk').reduce((s, t) => s + t.amount, 0)
  const cats = S.spendingByCategory(state, m)
  const maxCat = cats.length ? cats[0].amount : 0

  return `
  <header class="view-head">
    <p class="eyebrow">Catatan</p>
    <h1 class="h1">Keluar &amp; masuk</h1>
    <p class="lede">Setiap pengeluaran kecil tetap punya tempat di sini.</p>
  </header>

  <div class="summary2">
    <div><span class="k">Keluar</span><span class="v out">${F.fmtRp(spent)}</span></div>
    <div><span class="k">Masuk</span><span class="v in">${F.fmtRp(masuk)}</span></div>
  </div>

  <button type="button" class="btn btn-primary btn-block" data-act="add-txn">+ Catat transaksi</button>

  ${cats.length ? `
  <section class="section">
    <div class="section-head"><h2 class="h2">Ke mana perginya</h2><span class="hint">${cats.length} kategori</span></div>
    <div class="cats">
      ${cats.slice(0, 6).map((c) => `
        <div class="catrow">
          <span class="name">${F.esc(c.name)}</span>
          <span class="val">${F.fmtRp(c.amount)}</span>
          <span class="catbar"><i style="width:${maxCat > 0 ? Math.round((c.amount / maxCat) * 100) : 0}%"></i></span>
        </div>`).join('')}
    </div>
  </section>` : ''}

  ${groups.length ? groups.map((g) => `
    <section class="daygroup">
      <div class="dayhead">
        <span>${F.fmtDayHead(g.date)}</span>
        <span class="net">${g.net < 0 ? '−' : '+'}${F.fmtRp(Math.abs(g.net))}</span>
      </div>
      ${g.items.map((t) => `
        <div class="txn">
          <div class="txn-main">
            <p class="txn-note">${F.esc(t.note || t.category || 'Tanpa keterangan')}</p>
            <p class="txn-sub">${F.esc(t.category || 'Lainnya')}</p>
          </div>
          <span class="txn-amt ${t.type === 'masuk' ? 'is-in' : 'is-out'}">${t.type === 'masuk' ? '+' : '−'}${F.fmtRp(t.amount)}</span>
          <button type="button" class="icon-btn" data-act="del-txn" data-id="${t.id}" aria-label="Hapus catatan">✕</button>
        </div>`).join('')}
    </section>`).join('') : `
    <div class="empty">
      <h3>Masih bersih.</h3>
      <p>Catat pengeluaran pertama bulan ini — sekecil apa pun. Angka di ringkasan ikut bergerak.</p>
      <button type="button" class="btn btn-primary" data-act="add-txn">Catat sekarang</button>
    </div>`}`
}

function txnSheet() {
  const cats = S.CATEGORIES.map((c) => `<option value="${c}">${c}</option>`).join('')
  openSheet({
    title: 'Catat transaksi',
    sub: 'Pengeluaran atau pemasukan di luar gaji.',
    body: `
      <div class="segmented" role="group" aria-label="Jenis transaksi">
        <button type="button" data-seg="keluar" class="is-active" data-tone="out">Keluar</button>
        <button type="button" data-seg="masuk" data-tone="in">Masuk</button>
        <input type="hidden" name="type" value="keluar">
      </div>
      <div class="field">
        <label for="t-amount">Nominal</label>
        <div class="money-wrap"><span class="prefix">Rp</span>
          <input id="t-amount" name="amount" data-money inputmode="numeric" placeholder="0" required autocomplete="off">
        </div>
      </div>
      <div class="field-row">
        <div class="field">
          <label for="t-cat">Kategori</label>
          <select id="t-cat" name="category">${cats}</select>
        </div>
        <div class="field">
          <label for="t-date">Tanggal</label>
          <input type="date" id="t-date" name="date" value="${F.todayISO()}">
        </div>
      </div>
      <div class="field">
        <label for="t-note">Catatan</label>
        <input id="t-note" name="note" placeholder="mis. nasi padang, bensin" maxlength="80" autocomplete="off">
      </div>`,
    onSubmit: (fd, fail) => {
      const amount = F.parseRp(fd.get('amount'))
      if (amount <= 0) return fail('Nominal belum diisi.')
      const type = fd.get('type') === 'masuk' ? 'masuk' : 'keluar'
      const date = String(fd.get('date') || F.todayISO())
      state.txns.push({
        id: S.uid(),
        date,
        type,
        category: String(fd.get('category') || 'Lainnya'),
        note: String(fd.get('note') || '').trim(),
        amount,
        createdAt: Date.now(),
      })
      state.month = date.slice(0, 7)
      persist()
      render()
      toast(`${type === 'masuk' ? 'Pemasukan' : 'Pengeluaran'} ${F.fmtRp(amount)} dicatat.`)
      return true
    },
  })
}

/* ---------- pengaturan ---------- */

function settingsSheet() {
  const canPick = !!native?.pickBackup
  openPanel({
    title: 'Pengaturan',
    sub: 'Data disimpan di perangkat ini. Tidak ada akun, tidak ada server.',
    body: `
      <div class="settings">
        <button type="button" class="btn btn-ghost btn-block" data-act="export">Unduh cadangan (JSON)</button>
        ${canPick
          ? `<button type="button" class="btn btn-ghost btn-block" data-act="import-native">Pulihkan dari cadangan</button>`
          : `<label class="btn btn-ghost btn-block" for="import-file">Pulihkan dari cadangan</label>
             <input type="file" id="import-file" accept="application/json,.json" hidden>`}
        <p class="hint">Cadangan berguna sebelum ganti HP atau membersihkan data aplikasi.</p>
        <button type="button" class="btn btn-danger btn-block" data-act="reset">Hapus semua data</button>
      </div>`,
    after: (root) => {
      root.querySelector('#import-file')?.addEventListener('change', (e) => {
        const file = e.target.files?.[0]
        if (file) importData(file)
      })
    },
  })
}

function exportData() {
  const json = JSON.stringify(state, null, 2)
  if (native?.saveBackup) {
    let ok = false
    try {
      ok = native.saveBackup(`ry-money-${F.todayISO()}.json`, json)
    } catch (err) {
      console.error(err)
    }
    toast(ok ? 'Cadangan disimpan di Download/Ry-Money.' : 'Gagal menyimpan cadangan.')
    return
  }
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `ry-money-${F.todayISO()}.json`
  document.body.appendChild(a)
  a.click()
  a.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
  toast('Cadangan diunduh.')
}

function applyBackup(text) {
  try {
    const data = JSON.parse(String(text))
    if (!data || !Array.isArray(data.incomes) || !Array.isArray(data.txns)) {
      throw new Error('bukan berkas cadangan Ry-Money')
    }
    Object.assign(state, S.defaultState(), data)
    persist()
    sheet.close()
    render()
    toast('Data dipulihkan.')
    return true
  } catch (err) {
    alert(`Berkas tidak dikenali: ${err.message}`)
    return false
  }
}

function importData(file) {
  const reader = new FileReader()
  reader.onload = () => applyBackup(String(reader.result))
  reader.readAsText(file)
}

/* ---------- animasi kecil ---------- */

function animateBalance() {
  const el = document.querySelector('[data-count]')
  if (!el) return
  const key = `${route}|${state.month}`
  if (key === animatedKey) return
  animatedKey = key
  const target = Number(el.dataset.count) || 0
  if (target === 0 || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  const dur = 680
  const start = performance.now()
  const tick = (now) => {
    const p = Math.min(1, (now - start) / dur)
    const eased = 1 - Math.pow(1 - p, 3)
    el.textContent = F.fmtRp(target * eased)
    if (p < 1) requestAnimationFrame(tick)
    else el.textContent = F.fmtRp(target)
  }
  requestAnimationFrame(tick)
}

/* ---------- mulai ---------- */

// Jembatan kecil untuk pembungkus Android (APK).
window.__ryBack = () => {
  if (sheet.open) {
    sheet.close()
    return true
  }
  return false
}
window.__ryRestore = (text) => applyBackup(text)

let resizeTimer
window.addEventListener('resize', () => {
  clearTimeout(resizeTimer)
  resizeTimer = setTimeout(fitFigures, 150)
})

setRoute()

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').catch(() => {})
  })
}
