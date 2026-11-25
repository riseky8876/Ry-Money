// store.js — state, penyimpanan lokal, dan semua hitungan. Tanpa dependensi.

const KEY = 'rymoney.v1'

export const CYCLE_FACTOR = { harian: 30, mingguan: 4.345, bulanan: 1 }
export const PERIOD_DAYS = { hari: 1, minggu: 7, bulan: 30.4375 }
export const CYCLE_LABEL = { harian: 'per hari', mingguan: 'per minggu', bulanan: 'per bulan' }
export const PERIOD_LABEL = { hari: 'per hari', minggu: 'per minggu', bulan: 'per bulan' }
export const CATEGORIES = ['Makan', 'Transport', 'Kos', 'Tagihan', 'Belanja', 'Hiburan', 'Kesehatan', 'Lainnya']

export const uid = () =>
  crypto.randomUUID
    ? crypto.randomUUID()
    : 'id-' + Math.random().toString(36).slice(2, 10) + Date.now().toString(36)

const pad = (n) => String(n).padStart(2, '0')

export function monthKey(date = new Date()) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}`
}

export function defaultState() {
  return {
    version: 1,
    month: monthKey(),
    incomes: [],
    routines: [],
    goals: [],
    txns: [],
  }
}

export function loadState() {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return defaultState()
    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== 'object') return defaultState()
    const base = defaultState()
    return {
      ...base,
      ...parsed,
      month: typeof parsed.month === 'string' && /^\d{4}-\d{2}$/.test(parsed.month) ? parsed.month : base.month,
      incomes: Array.isArray(parsed.incomes) ? parsed.incomes : [],
      routines: Array.isArray(parsed.routines) ? parsed.routines : [],
      goals: Array.isArray(parsed.goals) ? parsed.goals : [],
      txns: Array.isArray(parsed.txns) ? parsed.txns : [],
    }
  } catch (err) {
    console.warn('Data lokal tidak terbaca, mulai dari kosong.', err)
    return defaultState()
  }
}

export function saveState(state) {
  try {
    localStorage.setItem(KEY, JSON.stringify(state))
    return true
  } catch (err) {
    console.error(err)
    return false
  }
}

// Satu rutinitas: nominal x berapa kali dalam sebulan.
export const routineMonthly = (r) => Math.round((Number(r.amount) || 0) * (CYCLE_FACTOR[r.cycle] ?? 1))

export const plannedMonthly = (routines) => routines.filter((r) => r.active).reduce((sum, r) => sum + routineMonthly(r), 0)

export const goalSaved = (g) => (g.deposits || []).reduce((sum, d) => sum + (Number(d.amount) || 0), 0)

export function goalEta(g) {
  const saved = goalSaved(g)
  const remaining = Math.max(0, (Number(g.target) || 0) - saved)
  const perPeriod = Number(g.planAmount) || 0
  const perDay = perPeriod / (PERIOD_DAYS[g.planPeriod] ?? 30.4375)
  const days = perDay > 0 ? remaining / perDay : null
  return { saved, remaining, perDay, days, done: remaining === 0 && (Number(g.target) || 0) > 0 }
}

const inMonth = (date, m) => typeof date === 'string' && date.slice(0, 7) === m

export function monthTotals(state, m) {
  let income = 0
  let allocated = 0
  for (const inc of state.incomes) {
    if (!inMonth(inc.date, m)) continue
    income += Number(inc.amount) || 0
    allocated += (inc.allocations || []).reduce((s, a) => s + (Number(a.amount) || 0), 0)
  }

  let saved = 0
  for (const g of state.goals) {
    for (const d of g.deposits || []) if (inMonth(d.date, m)) saved += Number(d.amount) || 0
  }

  let spent = 0
  let extra = 0
  for (const t of state.txns) {
    if (!inMonth(t.date, m)) continue
    if (t.type === 'masuk') extra += Number(t.amount) || 0
    else spent += Number(t.amount) || 0
  }

  return { income, extra, allocated, saved, spent, available: income + extra - allocated - saved - spent }
}

export function spendingByCategory(state, m) {
  const map = new Map()
  for (const t of state.txns) {
    if (t.type !== 'keluar' || !inMonth(t.date, m)) continue
    const key = t.category || 'Lainnya'
    map.set(key, (map.get(key) || 0) + (Number(t.amount) || 0))
  }
  return [...map.entries()].map(([name, amount]) => ({ name, amount })).sort((a, b) => b.amount - a.amount)
}

export function groupTxnsByDay(txns) {
  const groups = new Map()
  for (const t of txns) {
    if (!groups.has(t.date)) groups.set(t.date, [])
    groups.get(t.date).push(t)
  }
  return [...groups.entries()]
    .sort((a, b) => b[0].localeCompare(a[0]))
    .map(([date, items]) => ({
      date,
      items: items.slice().sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0)),
      net: items.reduce((s, t) => s + (t.type === 'masuk' ? t.amount : -t.amount), 0),
    }))
}
