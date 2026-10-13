import { Plant } from '../model/types';
import { addDays, diffDays, dueInfo, toDate, today } from './format';

export const UPCOMING_WINDOW_DAYS: number = 14;

class Season {
  key: string = '';
  name: string = '';
  months: number[] = [];
  waterInterval: number = 10;
}

function seasons(): Season[] {
  const list: Season[] = [];
  const keys: string[] = ['spring', 'summer', 'autumn', 'winter'];
  const names: string[] = ['春', '夏', '秋', '冬'];
  const months: number[][] = [[3, 4, 5], [6, 7, 8], [9, 10, 11], [12, 1, 2]];
  const intervals: number[] = [10, 5, 10, 15];
  for (let i = 0; i < keys.length; i++) {
    const season = new Season();
    season.key = keys[i];
    season.name = names[i];
    season.months = months[i];
    season.waterInterval = intervals[i];
    list.push(season);
  }
  return list;
}

export function currentSeason(date: Date): Season {
  const month = date.getMonth() + 1;
  const list = seasons();
  for (let i = 0; i < list.length; i++) {
    const months = list[i].months;
    for (let j = 0; j < months.length; j++) {
      if (months[j] === month) return list[i];
    }
  }
  return list[0];
}

export function waterIntervalFor(plant: Plant, date: Date): number {
  if (plant.customWaterInterval > 0) return plant.customWaterInterval;
  return currentSeason(date).waterInterval;
}

export function fertIntervalFor(plant: Plant): number {
  if (plant.customFertInterval > 0) return plant.customFertInterval;
  return 30;
}

export function repotIntervalFor(plant: Plant): number {
  if (plant.customRepotInterval > 0) return plant.customRepotInterval;
  return 365;
}

export function lastCareDate(plant: Plant, type: string): string {
  let latest = '';
  const records = plant.records;
  for (let i = 0; i < records.length; i++) {
    const record = records[i];
    if (record.type === type && record.date > latest && toDate(record.date) !== null) {
      latest = record.date;
    }
  }
  if (latest.length > 0) return latest;
  if (toDate(plant.companionStart) !== null) return plant.companionStart;
  if (toDate(plant.purchaseDate) !== null) return plant.purchaseDate;
  return '';
}

export function nextDueDate(plant: Plant, type: string): string {
  let last = '';
  let interval = 0;
  if (type === 'water') {
    last = lastCareDate(plant, '浇水');
    interval = waterIntervalFor(plant, new Date());
  } else if (type === 'fertilize') {
    last = lastCareDate(plant, '施肥');
    interval = fertIntervalFor(plant);
  } else if (type === 'repot') {
    last = lastCareDate(plant, '换盆');
    interval = repotIntervalFor(plant);
  }
  if (last.length === 0) return '';
  return addDays(last, interval);
}

export class TaskItem {
  type: string = '';
  label: string = '';
  due: string = '';
  dueText: string = '';
  overdue: boolean = false;
}

export function plantTasks(plant: Plant, upcomingDays: number): TaskItem[] {
  const windowDays = upcomingDays >= 0 ? upcomingDays : UPCOMING_WINDOW_DAYS;
  const tasks: TaskItem[] = [];
  const types: string[] = ['water', 'fertilize', 'repot'];
  const labels: string[] = ['浇水', '施肥', '换盆'];
  for (let i = 0; i < types.length; i++) {
    const due = nextDueDate(plant, types[i]);
    if (due.length === 0) continue;
    const info = dueInfo(due);
    const daysUntilDue = diffDays(today(), due);
    if (info.overdue || (daysUntilDue >= 0 && daysUntilDue <= windowDays)) {
      const task = new TaskItem();
      task.type = types[i];
      task.label = labels[i];
      task.due = due;
      task.dueText = info.text;
      task.overdue = info.overdue;
      tasks.push(task);
    }
  }
  tasks.sort((a: TaskItem, b: TaskItem): number => {
    if (a.overdue === b.overdue) {
      if (a.due < b.due) return -1;
      if (a.due > b.due) return 1;
      return 0;
    }
    return a.overdue ? -1 : 1;
  });
  return tasks;
}

export function seasonWaterText(): string {
  const season = currentSeason(new Date());
  return '当前' + season.name + '季，默认每 ' + season.waterInterval + ' 天浇一次水';
}
