const format = require('./format');
const UPCOMING_WINDOW_DAYS = 14;

const SEASONS = [
  { key: 'spring', name: '春', months: [3, 4, 5], waterInterval: 10 },
  { key: 'summer', name: '夏', months: [6, 7, 8], waterInterval: 5 },
  { key: 'autumn', name: '秋', months: [9, 10, 11], waterInterval: 10 },
  { key: 'winter', name: '冬', months: [12, 1, 2], waterInterval: 15 }
];

function currentSeason(date) {
  const d = date || new Date();
  const m = d.getMonth() + 1;
  for (const s of SEASONS) {
    if (s.months.includes(m)) return s;
  }
  return SEASONS[0];
}

function waterIntervalFor(plant, date) {
  if (plant && plant.customWaterInterval && Number(plant.customWaterInterval) > 0) {
    return Number(plant.customWaterInterval);
  }
  return currentSeason(date).waterInterval;
}

function fertIntervalFor(plant) {
  if (plant && plant.customFertInterval && Number(plant.customFertInterval) > 0) {
    return Number(plant.customFertInterval);
  }
  return 30;
}

function repotIntervalFor(plant) {
  if (plant && plant.customRepotInterval && Number(plant.customRepotInterval) > 0) {
    return Number(plant.customRepotInterval);
  }
  return 365;
}

function lastCareDate(plant, type) {
  const records = (plant.records || []).filter(r => r.type === type && format.toDate(r.date));
  let latest = '';
  for (const r of records) {
    if (r.date && r.date > latest) latest = r.date;
  }
  if (latest) return latest;
  if (format.toDate(plant.companionStart)) return plant.companionStart;
  if (format.toDate(plant.purchaseDate)) return plant.purchaseDate;
  return '';
}

function nextDueDate(plant, type) {
  let last = '';
  let interval = 0;
  if (type === 'water') {
    last = lastCareDate(plant, '浇水');
    interval = waterIntervalFor(plant);
  } else if (type === 'fertilize') {
    last = lastCareDate(plant, '施肥');
    interval = fertIntervalFor(plant);
  } else if (type === 'repot') {
    last = lastCareDate(plant, '换盆');
    interval = repotIntervalFor(plant);
  }
  if (!last) return '';
  return format.addDays(last, interval);
}

function plantTasks(plant, options) {
  const upcomingDays = options && Number.isFinite(Number(options.upcomingDays))
    ? Math.max(0, Number(options.upcomingDays))
    : UPCOMING_WINDOW_DAYS;
  const tasks = [];
  const defs = [
    { type: 'water', label: '浇水' },
    { type: 'fertilize', label: '施肥' },
    { type: 'repot', label: '换盆' }
  ];
  for (const def of defs) {
    const due = nextDueDate(plant, def.type);
    if (!due) continue;
    const info = format.dueInfo(due);
    const daysUntilDue = format.diffDays(format.today(), due);
    if (info.overdue || (daysUntilDue >= 0 && daysUntilDue <= upcomingDays)) {
      tasks.push({
        type: def.type,
        label: def.label,
        due,
        dueText: info.text,
        overdue: info.overdue
      });
    }
  }
  tasks.sort((a, b) => (a.overdue === b.overdue ? a.due.localeCompare(b.due) : a.overdue ? -1 : 1));
  return tasks;
}

function seasonWaterText(date) {
  const s = currentSeason(date);
  return '当前' + s.name + '季，默认每 ' + s.waterInterval + ' 天浇一次水';
}

module.exports = {
  SEASONS,
  UPCOMING_WINDOW_DAYS,
  currentSeason,
  waterIntervalFor,
  fertIntervalFor,
  repotIntervalFor,
  lastCareDate,
  nextDueDate,
  plantTasks,
  seasonWaterText
};
