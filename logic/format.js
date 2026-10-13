function pad(n) {
  return n < 10 ? '0' + n : '' + n;
}

function fmtDate(d) {
  if (!d) return '';
  const date = typeof d === 'string' ? toDate(d) : new Date(d);
  if (!date || Number.isNaN(date.getTime())) return '';
  return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate());
}

function today() {
  return fmtDate(new Date());
}

function toDate(str) {
  if (!str) return null;
  if (str instanceof Date) return Number.isNaN(str.getTime()) ? null : new Date(str);
  const matched = String(str).match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!matched) return null;
  const year = Number(matched[1]);
  const month = Number(matched[2]);
  const day = Number(matched[3]);
  const date = new Date(year, month - 1, day, 12, 0, 0, 0);
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
    return null;
  }
  return date;
}

function diffDays(a, b) {
  const da = toDate(a);
  const db = toDate(b);
  if (!da || !db) return 0;
  const utcA = Date.UTC(da.getFullYear(), da.getMonth(), da.getDate());
  const utcB = Date.UTC(db.getFullYear(), db.getMonth(), db.getDate());
  return Math.round((utcB - utcA) / 86400000);
}

function addDays(str, n) {
  const d = toDate(str);
  if (!d || !Number.isFinite(Number(n))) return '';
  d.setDate(d.getDate() + n);
  return fmtDate(d);
}

function companionText(startDate) {
  if (!startDate) return '未设置';
  const days = diffDays(startDate, today());
  if (days < 0) return '尚未开始';
  if (days === 0) return '今天加入';
  if (days < 30) return days + ' 天';
  const months = Math.floor(days / 30);
  const remDays = days % 30;
  if (months < 12) {
    return remDays > 0 ? months + ' 个月 ' + remDays + ' 天' : months + ' 个月';
  }
  const years = Math.floor(months / 12);
  const remMonths = months % 12;
  return remMonths > 0 ? years + ' 年 ' + remMonths + ' 个月' : years + ' 年';
}

function dueInfo(dueDate) {
  if (!dueDate) return { text: '', overdue: false };
  const diff = diffDays(today(), dueDate);
  if (diff < 0) return { text: '逾期 ' + (-diff) + ' 天', overdue: true };
  if (diff === 0) return { text: '今天到期', overdue: false };
  return { text: '还有 ' + diff + ' 天', overdue: false };
}

function money(n) {
  const v = Number(n) || 0;
  const s = v.toFixed(2);
  return s.replace(/\.00$/, '').replace(/(\.\d)0$/, '$1');
}

module.exports = { fmtDate, today, toDate, diffDays, addDays, companionText, dueInfo, money };
