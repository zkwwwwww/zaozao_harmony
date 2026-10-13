import { Bundle, EnvCard, Environment, HomeStats, Plant, PlantCard, TaskRow } from '../model/types';
import { dueInfo, money, today } from './format';
import { nextDueDate, plantTasks } from './reminder';

export function findEnv(envs: Environment[], id: string): Environment | null {
  for (let i = 0; i < envs.length; i++) {
    if (envs[i].id === id) return envs[i];
  }
  return null;
}

export function findPlant(plants: Plant[], id: string): Plant | null {
  for (let i = 0; i < plants.length; i++) {
    if (plants[i].id === id) return plants[i];
  }
  return null;
}

export function activePlants(bundle: Bundle): Plant[] {
  const list: Plant[] = [];
  for (let i = 0; i < bundle.plants.length; i++) {
    if (!bundle.plants[i].memorialized) list.push(bundle.plants[i]);
  }
  return list;
}

function waterTone(overdue: boolean, due: string): string {
  if (overdue) return 'overdue';
  if (due === today()) return 'today';
  return 'soon';
}

export function buildCards(bundle: Bundle): PlantCard[] {
  const plants = activePlants(bundle);
  const cards: PlantCard[] = [];
  for (let i = 0; i < plants.length; i++) {
    const plant = plants[i];
    const card = new PlantCard();
    card.id = plant.id;
    card.name = plant.name;
    card.variety = plant.variety;
    card.status = plant.status.length > 0 ? plant.status : '健康';
    card.price = plant.price;
    card.planting = plant.planting;
    const env = findEnv(bundle.envs, plant.environmentId);
    if (env !== null) {
      card.envName = env.name;
    } else if (plant.location.length > 0) {
      card.envName = plant.location;
    } else {
      card.envName = '未分类';
    }
    if (plant.photos.length > 0) card.photo = plant.photos[0];
    const due = nextDueDate(plant, 'water');
    if (due.length > 0) {
      const info = dueInfo(due);
      card.waterTone = waterTone(info.overdue, due);
      card.waterText = (info.overdue ? '待浇水 · ' : '下次浇水 · ') + info.text;
    }
    cards.push(card);
  }
  return cards;
}

export function buildTasks(bundle: Bundle): TaskRow[] {
  const plants = activePlants(bundle);
  const rows: TaskRow[] = [];
  for (let i = 0; i < plants.length; i++) {
    const plant = plants[i];
    const tasks = plantTasks(plant, UPCOMING_WINDOW_DAYS);
    for (let t = 0; t < tasks.length; t++) {
      const task = tasks[t];
      const row = new TaskRow();
      row.key = plant.id + '_' + task.type;
      row.plantId = plant.id;
      row.plantName = plant.name;
      row.photo = plant.photos.length > 0 ? plant.photos[0] : '';
      row.type = task.type;
      row.label = task.label;
      row.due = task.due;
      row.dueText = task.dueText;
      row.overdue = task.overdue;
      rows.push(row);
    }
  }
  rows.sort((a: TaskRow, b: TaskRow): number => {
    if (a.overdue === b.overdue) {
      if (a.due < b.due) return -1;
      if (a.due > b.due) return 1;
      return 0;
    }
    return a.overdue ? -1 : 1;
  });
  return rows;
}

export function buildStats(bundle: Bundle, tasks: TaskRow[]): HomeStats {
  const stats = new HomeStats();
  const plants = activePlants(bundle);
  stats.count = plants.length;
  let total = 0;
  for (let i = 0; i < plants.length; i++) {
    total += Number(plants[i].price) || 0;
  }
  stats.totalPrice = money(total);
  const day = today();
  for (let i = 0; i < tasks.length; i++) {
    if (tasks[i].overdue) stats.overdue += 1;
    if (tasks[i].type === 'water' && !tasks[i].overdue && tasks[i].due === day) stats.waterToday += 1;
  }
  return stats;
}

export function buildEnvCards(bundle: Bundle): EnvCard[] {
  const plants = activePlants(bundle);
  const cards: EnvCard[] = [];
  for (let i = 0; i < bundle.envs.length; i++) {
    const env = bundle.envs[i];
    const card = new EnvCard();
    card.id = env.id;
    card.name = env.name;
    card.lightIntensity = env.lightIntensity;
    card.lightHours = env.lightHours;
    for (let p = 0; p < plants.length; p++) {
      if (plants[p].environmentId === env.id) card.count += 1;
    }
    cards.push(card);
  }
  return cards;
}

export function filterCards(cards: PlantCard[], keyword: string, status: string): PlantCard[] {
  const key = keyword.trim().toLowerCase();
  const result: PlantCard[] = [];
  for (let i = 0; i < cards.length; i++) {
    const card = cards[i];
    if (status.length > 0 && card.status !== status) continue;
    if (key.length > 0) {
      const hay = (card.name + ' ' + card.variety + ' ' + card.envName).toLowerCase();
      if (hay.indexOf(key) < 0) continue;
    }
    result.push(card);
  }
  return result;
}

export function memorialPlants(bundle: Bundle): Plant[] {
  const list: Plant[] = [];
  for (let i = 0; i < bundle.plants.length; i++) {
    if (bundle.plants[i].memorialized) list.push(bundle.plants[i]);
  }
  list.sort((a: Plant, b: Plant): number => {
    if (a.memorialDate === b.memorialDate) return b.updatedAt - a.updatedAt;
    if (a.memorialDate < b.memorialDate) return 1;
    return -1;
  });
  return list;
}
