import { Environment, LuxRow } from '../model/types';

export const APP_VERSION: string = '1.0.0';
export const STATUS_OPTIONS: string[] = ['健康', '生长中', '休眠', '状态一般', '需要关注', '生病中'];
export const PLANTING_OPTIONS: string[] = ['水苔', '土培', '水培', '板植', '颗粒'];
export const CARE_TYPES: string[] = ['浇水', '施肥', '修剪', '换盆', '防治病虫害', '测量'];
export const PURCHASE_OPTIONS: string[] = ['实体花市', '花店', '线上网店', '网购拼团', '朋友赠送', '自己繁育', '其他'];
export const MEMORIAL_TYPES: string[] = ['送人', '去世'];

export function defaultEnvironments(): Environment[] {
  const names: string[] = ['室内明亮', '半阴散射光', '阳台直射', '弱光阴处'];
  const lux: string[] = ['5000', '3000', '8000', '1500'];
  const hours: string[] = ['8', '6', '10', '4'];
  const list: Environment[] = [];
  for (let i = 0; i < names.length; i++) {
    const env = new Environment();
    env.id = 'env_' + (i + 1);
    env.name = names[i];
    env.lightIntensity = lux[i];
    env.lightHours = hours[i];
    env.sortOrder = i + 1;
    list.push(env);
  }
  return list;
}

export function luxRows(): LuxRow[] {
  const labels: string[] = ['直射阳光', '明亮散射光', '半阴散射光', '弱光阴处'];
  const values: string[] = ['10,000 – 100,000', '5,000 – 10,000', '2,000 – 5,000', '小于 2,000'];
  const rows: LuxRow[] = [];
  for (let i = 0; i < labels.length; i++) {
    const row = new LuxRow();
    row.label = labels[i];
    row.value = values[i];
    rows.push(row);
  }
  return rows;
}

export function careLabel(type: string): string {
  if (type === 'water') return '浇水';
  if (type === 'fertilize') return '施肥';
  if (type === 'repot') return '换盆';
  return type;
}

export function newId(prefix: string): string {
  return prefix + '_' + Date.now() + '_' + Math.floor(Math.random() * 1000);
}
