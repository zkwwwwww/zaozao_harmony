import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { CareRecord, Environment, Plant } from '../model/types';
import { newId } from '../common/constants';
import { PlantRepository } from './PlantRepository';
import { deleteIfOwned, readBase64, writeBase64 } from './Media';

class BackupPhoto {
  ext: string = '';
  data: string = '';
}

class BackupRecord {
  id: string = '';
  type: string = '';
  date: string = '';
  content: string = '';
  createdAt: number = 0;
  photo: BackupPhoto | null = null;
}

class BackupEnv {
  id: string = '';
  name: string = '';
  lightIntensity: string = '';
  lightHours: string = '';
  sortOrder: number = 0;
}

class BackupPlant {
  id: string = '';
  name: string = '';
  variety: string = '';
  status: string = '';
  price: string = '';
  purchaseWay: string = '';
  planting: string = '';
  environmentId: string = '';
  location: string = '';
  companionStart: string = '';
  purchaseDate: string = '';
  description: string = '';
  customWaterInterval: number = 0;
  customFertInterval: number = 0;
  customRepotInterval: number = 0;
  memorialized: boolean = false;
  memorialType: string = '';
  memorialDate: string = '';
  memorialNote: string = '';
  companionSnapshot: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
  photos: BackupPhoto[] = [];
  records: BackupRecord[] = [];
}

class BackupFile {
  version: number = 1;
  exportedAt: string = '';
  environments: BackupEnv[] = [];
  plants: BackupPlant[] = [];
}

function strField(obj: ESObject, key: string): string {
  const value: ESObject = obj[key] as ESObject;
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return String(value);
  return '';
}

function numField(obj: ESObject, key: string): number {
  const value: ESObject = obj[key] as ESObject;
  if (typeof value === 'number') return value as number;
  if (typeof value === 'string') {
    const n = Number(value as string);
    return Number.isFinite(n) ? n : 0;
  }
  return 0;
}

function boolField(obj: ESObject, key: string): boolean {
  const value: ESObject = obj[key] as ESObject;
  if (typeof value === 'boolean') return value as boolean;
  if (typeof value === 'number') return (value as number) !== 0;
  return false;
}

function objectItems(obj: ESObject, key: string): ESObject[] {
  const value: ESObject = obj[key] as ESObject;
  const list: ESObject[] = [];
  if (!Array.isArray(value)) return list;
  for (let i = 0; i < value.length; i++) {
    const item: ESObject = value[i] as ESObject;
    if (item !== null && typeof item === 'object') list.push(item);
  }
  return list;
}

function safeExt(ext: string): string {
  const lower = ext.toLowerCase();
  if (lower === 'png' || lower === 'jpg' || lower === 'webp' || lower === 'gif') return lower;
  return 'jpg';
}

function photoExt(path: string): string {
  const dot = path.lastIndexOf('.');
  if (dot < 0) return 'jpg';
  return safeExt(path.substring(dot + 1));
}

function isCancel(err: Object): boolean {
  const text = err instanceof Error ? err.message.toLowerCase() : '';
  return text.indexOf('cancel') >= 0 || text.indexOf('取消') >= 0;
}

export function buildExportJson(): string {
  const bundle = PlantRepository.current();
  const file = new BackupFile();
  file.version = 1;
  file.exportedAt = new Date().toISOString();
  for (let i = 0; i < bundle.envs.length; i++) {
    const env = bundle.envs[i];
    const item = new BackupEnv();
    item.id = env.id;
    item.name = env.name;
    item.lightIntensity = env.lightIntensity;
    item.lightHours = env.lightHours;
    item.sortOrder = env.sortOrder;
    file.environments.push(item);
  }
  for (let i = 0; i < bundle.plants.length; i++) {
    file.plants.push(plantToBackup(bundle.plants[i]));
  }
  return JSON.stringify(file);
}

function plantToBackup(plant: Plant): BackupPlant {
  const item = new BackupPlant();
  item.id = plant.id;
  item.name = plant.name;
  item.variety = plant.variety;
  item.status = plant.status;
  item.price = plant.price;
  item.purchaseWay = plant.purchaseWay;
  item.planting = plant.planting;
  item.environmentId = plant.environmentId;
  item.location = plant.location;
  item.companionStart = plant.companionStart;
  item.purchaseDate = plant.purchaseDate;
  item.description = plant.description;
  item.customWaterInterval = plant.customWaterInterval;
  item.customFertInterval = plant.customFertInterval;
  item.customRepotInterval = plant.customRepotInterval;
  item.memorialized = plant.memorialized;
  item.memorialType = plant.memorialType;
  item.memorialDate = plant.memorialDate;
  item.memorialNote = plant.memorialNote;
  item.companionSnapshot = plant.companionSnapshot;
  item.createdAt = plant.createdAt;
  item.updatedAt = plant.updatedAt;
  for (let i = 0; i < plant.photos.length; i++) {
    const data = readBase64(plant.photos[i]);
    if (data.length === 0) continue;
    const photo = new BackupPhoto();
    photo.ext = photoExt(plant.photos[i]);
    photo.data = data;
    item.photos.push(photo);
  }
  for (let i = 0; i < plant.records.length; i++) {
    const record = plant.records[i];
    const copy = new BackupRecord();
    copy.id = record.id;
    copy.type = record.type;
    copy.date = record.date;
    copy.content = record.content;
    copy.createdAt = record.createdAt;
    if (record.photo.length > 0) {
      const data = readBase64(record.photo);
      if (data.length > 0) {
        const photo = new BackupPhoto();
        photo.ext = photoExt(record.photo);
        photo.data = data;
        copy.photo = photo;
      }
    }
    item.records.push(copy);
  }
  return item;
}

export async function importJson(text: string): Promise<void> {
  if (text.trim().length === 0) throw new Error('备份文件是空的');
  let root: ESObject;
  try {
    root = JSON.parse(text) as ESObject;
  } catch (err) {
    throw new Error('备份文件无法识别');
  }
  if (numField(root, 'version') !== 1) throw new Error('还不认识这个备份版本');
  const envs = parseEnvs(objectItems(root, 'environments'));
  const created: string[] = [];
  let plants: Plant[] = [];
  try {
    plants = parsePlants(objectItems(root, 'plants'), created);
    await PlantRepository.importAll(envs, plants);
  } catch (err) {
    for (let i = 0; i < created.length; i++) deleteIfOwned(created[i]);
    throw err instanceof Error ? err : new Error('导入失败');
  }
}

function parseEnvs(items: ESObject[]): Environment[] {
  const list: Environment[] = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const name = strField(item, 'name').trim();
    if (name.length === 0) continue;
    const env = new Environment();
    const id = strField(item, 'id').trim();
    env.id = id.length > 0 ? id : newId('env');
    env.name = name;
    env.lightIntensity = strField(item, 'lightIntensity').trim();
    env.lightHours = strField(item, 'lightHours').trim();
    env.sortOrder = numField(item, 'sortOrder');
    if (env.sortOrder === 0) env.sortOrder = i + 1;
    list.push(env);
  }
  return list;
}

function parsePlants(items: ESObject[], created: string[]): Plant[] {
  const list: Plant[] = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const name = strField(item, 'name').trim();
    if (name.length === 0) continue;
    const plant = new Plant();
    const id = strField(item, 'id').trim();
    plant.id = id.length > 0 ? id : newId('plant');
    plant.name = name;
    plant.variety = strField(item, 'variety');
    plant.status = strField(item, 'status');
    if (plant.status.length === 0) plant.status = '健康';
    plant.price = strField(item, 'price');
    plant.purchaseWay = strField(item, 'purchaseWay');
    plant.planting = strField(item, 'planting');
    plant.environmentId = strField(item, 'environmentId');
    plant.location = strField(item, 'location');
    plant.companionStart = strField(item, 'companionStart');
    plant.purchaseDate = strField(item, 'purchaseDate');
    plant.description = strField(item, 'description');
    plant.customWaterInterval = numField(item, 'customWaterInterval');
    plant.customFertInterval = numField(item, 'customFertInterval');
    plant.customRepotInterval = numField(item, 'customRepotInterval');
    plant.memorialized = boolField(item, 'memorialized');
    plant.memorialType = strField(item, 'memorialType');
    plant.memorialDate = strField(item, 'memorialDate');
    plant.memorialNote = strField(item, 'memorialNote');
    plant.companionSnapshot = strField(item, 'companionSnapshot');
    plant.createdAt = numField(item, 'createdAt');
    plant.updatedAt = numField(item, 'updatedAt');
    if (plant.createdAt === 0) plant.createdAt = Date.now();
    if (plant.updatedAt === 0) plant.updatedAt = plant.createdAt;
    const photos = objectItems(item, 'photos');
    for (let p = 0; p < photos.length; p++) {
      const data = strField(photos[p], 'data');
      if (data.length === 0) continue;
      const path = writeBase64(data, safeExt(strField(photos[p], 'ext')));
      created.push(path);
      plant.photos.push(path);
    }
    const records = objectItems(item, 'records');
    for (let r = 0; r < records.length; r++) {
      const source = records[r];
      const record = new CareRecord();
      const recordId = strField(source, 'id').trim();
      record.id = recordId.length > 0 ? recordId : newId('rec');
      record.plantId = plant.id;
      record.type = strField(source, 'type');
      record.date = strField(source, 'date');
      record.content = strField(source, 'content');
      record.createdAt = numField(source, 'createdAt');
      if (record.createdAt === 0) record.createdAt = Date.now();
      const photoItems = objectItems(source, 'photo');
      if (photoItems.length === 0 && typeof source['photo'] === 'object' && source['photo'] !== null) {
        const photoObj = source['photo'] as ESObject;
        const data = strField(photoObj, 'data');
        if (data.length > 0) {
          record.photo = writeBase64(data, safeExt(strField(photoObj, 'ext')));
          created.push(record.photo);
        }
      }
      plant.records.push(record);
    }
    list.push(plant);
  }
  return list;
}

function readText(uri: string): string {
  const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
  const stat = fileIo.statSync(file.fd);
  const buf = new ArrayBuffer(stat.size);
  fileIo.readSync(file.fd, buf);
  fileIo.closeSync(file);
  const decoder = util.TextDecoder.create('utf-8', { fatal: false, ignoreBOM: true });
  return decoder.decodeToString(new Uint8Array(buf));
}

export async function exportBackup(context: common.UIAbilityContext): Promise<string> {
  const json = buildExportJson();
  const documentPicker = new picker.DocumentViewPicker(context);
  let uris: string[] = [];
  try {
    uris = await documentPicker.save({ newFileNames: ['zaozao-backup.json'] });
  } catch (err) {
    if (isCancel(err)) return '';
    throw new Error('导出失败，请重试');
  }
  if (uris.length === 0) return '';
  const file = fileIo.openSync(uris[0], fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
  fileIo.writeSync(file.fd, json);
  fileIo.closeSync(file);
  return '备份已保存';
}

export async function importBackup(context: common.UIAbilityContext): Promise<string> {
  const documentPicker = new picker.DocumentViewPicker(context);
  let uris: string[] = [];
  try {
    uris = await documentPicker.select({
      maxSelectNumber: 1,
      fileSuffixFilters: ['.json']
    });
  } catch (err) {
    if (isCancel(err)) return '';
    throw new Error('没有读到备份文件');
  }
  if (uris.length === 0) return '';
  await importJson(readText(uris[0]));
  return '备份已合并到本机';
}
