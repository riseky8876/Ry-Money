// format.js — angka, tanggal, dan teks aman untuk HTML.

const rp = new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 })
const num = new Intl.NumberFormat('id-ID')

export const fmtRp = (n) => rp.format(Math.round(Number(n) || 0)).replace(/\u00a0/g, ' ')
export const fmtNum = (n) => num.format(Math.round(Number(n) || 0))

export const parseRp = (v) => {
  const n = Number(String(v ?? '').replace(/[^\d]/g, ''))
  return Number.isFinite(n) ? n : 0
}

export const esc = (v) =>
  String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c])

const pad = (n) => String(n).padStart(2, '0')

export function todayISO() {
  const d = new Date()
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

const asDate = (iso) => new Date(`${iso}T00:00:00`)

export function fmtDate(iso) {
  if (!iso) return '—'
  return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }).format(asDate(iso))
}

export function fmtDayHead(iso) {
  const s = new Intl.DateTimeFormat('id-ID', { weekday: 'long', day: 'numeric', month: 'long' }).format(asDate(iso))
  return s.charAt(0).toUpperCase() + s.slice(1)
}

export function monthLabel(m) {
  const s = new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(asDate(`${m}-01`))
  return s.charAt(0).toUpperCase() + s.slice(1)
}

export function shiftMonth(m, delta) {
  const [y, mo] = m.split('-').map(Number)
  const d = new Date(y, mo - 1 + delta, 1)
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}`
}

// "≈ 8 minggu lagi" — perkiraan yang mudah dibaca.
export function etaLabel(days) {
  if (days === null) return 'rencana belum diisi'
  if (days <= 0) return 'sudah tercapai'
  if (days < 1) return 'kurang dari sehari lagi'
  if (days < 14) return `≈ ${Math.ceil(days)} hari lagi`
  if (days < 120) return `≈ ${Math.round(days / 7)} minggu lagi`
  if (days < 730) return `≈ ${Math.round(days / 30.44)} bulan lagi`
  return `≈ ${(days / 365).toFixed(1)} tahun lagi`
}
