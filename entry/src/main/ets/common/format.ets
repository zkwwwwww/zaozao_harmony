function pad(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

export function fmtParts(year: number, month: number, day: number): string {
  return year + '-' + pad(month) + '-' + pad(day);
}

export function fmtDate(d: Date): string {
  if (Number.isNaN(d.getTime())) return '';
  return fmtParts(d.getFullYear(), d.getMonth() + 1, d.getDate());
}

export function today(): string {
  return fmtDate(new Date());
}

export function toDate(str: string): Date | null {
  if (!str) return null;
  const matched = str.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (matched === null) return null;
  const year = Number(matched[1]);
  const month = Number(matched[2]);
  const day = Number(matched[3]);
  const date = new Date(year, month - 1, day, 12, 0, 0, 0);
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
    return null;
  }
  return date;
}

export function diffDays(a: string, b: string): number {
  const da = toDate(a);
  const db = toDate(b);
  if (da === null || db === null) return 0;
  const utcA = Date.UTC(da.getFullYear(), da.getMonth(), da.getDate());
  const utcB = Date.UTC(db.getFullYear(), db.getMonth(), db.getDate());
  return Math.round((utcB - utcA) / 86400000);
}

export function addDays(str: string, n: number): string {
  const d = toDate(str);
  if (d === null || !Number.isFinite(n)) return '';
  d.setDate(d.getDate() + n);
  return fmtDate(d);
}

export function companionText(startDate: string): string {
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

export class DueInfo {
  text: string = '';
  overdue: boolean = false;
}

export function dueInfo(dueDate: string): DueInfo {
  const info = new DueInfo();
  if (!dueDate) return info;
  const diff = diffDays(today(), dueDate);
  if (diff < 0) {
    info.text = '逾期 ' + (-diff) + ' 天';
    info.overdue = true;
    return info;
  }
  if (diff === 0) {
    info.text = '今天到期';
    return info;
  }
  info.text = '还有 ' + diff + ' 天';
  return info;
}

export function money(n: number | string): string {
  const v = Number(n) || 0;
  const s = v.toFixed(2);
  return s.replace(/\.00$/, '').replace(/(\.\d)0$/, '$1');
}

export function sanitizeDecimal(input: string): string {
  let result = '';
  let dot = false;
  for (let i = 0; i < input.length; i++) {
    const ch = input.charAt(i);
    if (ch >= '0' && ch <= '9') {
      result += ch;
    } else if (ch === '.' && !dot) {
      dot = true;
      result += ch;
    }
  }
  return result;
}

export function sanitizeInt(input: string): string {
  let result = '';
  for (let i = 0; i < input.length; i++) {
    const ch = input.charAt(i);
    if (ch >= '0' && ch <= '9') result += ch;
  }
  if (result.length > 4) return result.substring(0, 4);
  return result;
}

export function positiveInt(input: string): number {
  const n = Number(sanitizeInt(input));
  if (!Number.isFinite(n) || n <= 0) return 0;
  return Math.floor(n);
}

export function errorText(err: Object): string {
  if (err instanceof Error) return err.message;
  return '操作失败，请重试';
}

export function singleIndex(index: number | number[]): number {
  if (typeof index === 'number') return index;
  const list = index as number[];
  if (list.length === 0) return -1;
  return list[0];
}
