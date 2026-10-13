import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Bundle, CareRecord, Environment, Plant } from '../model/types';
import { defaultEnvironments, newId } from '../common/constants';
import { deleteIfOwned, bindFilesDir } from './Media';

let abilityContext: common.UIAbilityContext | null = null;

export function setAppContext(context: common.UIAbilityContext): void {
  abilityContext = context;
}

export function requireContext(): common.UIAbilityContext {
  if (abilityContext === null) {
    throw new Error('应用尚未初始化');
  }
  return abilityContext;
}

function cellString(result: relationalStore.ResultSet, name: string): string {
  const index = result.getColumnIndex(name);
  if (index < 0) return '';
  return result.getString(index);
}

function cellLong(result: relationalStore.ResultSet, name: string): number {
  const index = result.getColumnIndex(name);
  if (index < 0) return 0;
  return result.getLong(index);
}

function encodeList(list: string[]): string {
  return JSON.stringify(list);
}

function decodeList(raw: string): string[] {
  const list: string[] = [];
  if (raw.length === 0) return list;
  try {
    const parsed: ESObject = JSON.parse(raw) as ESObject;
    if (!Array.isArray(parsed)) return list;
    for (let i = 0; i < parsed.length; i++) {
      if (typeof parsed[i] === 'string') list.push(parsed[i] as string);
    }
  } catch (err) {
    return [];
  }
  return list;
}

export class PlantRepository {
  private static store: relationalStore.RdbStore | null = null;
  private static bundle: Bundle = new Bundle();
  static lastError: string = '';

  static current(): Bundle {
    return PlantRepository.bundle;
  }

  static async init(): Promise<void> {
    const context = requireContext();
    bindFilesDir(context.filesDir);
    const config: relationalStore.StoreConfig = {
      name: 'zaozao.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    PlantRepository.store = await relationalStore.getRdbStore(context, config);
    await PlantRepository.store.executeSql(
      'CREATE TABLE IF NOT EXISTS environments (id TEXT PRIMARY KEY, name TEXT, light_intensity TEXT, light_hours TEXT, sort_order INTEGER)'
    );
    await PlantRepository.store.executeSql(
      'CREATE TABLE IF NOT EXISTS plants (id TEXT PRIMARY KEY, name TEXT, variety TEXT, status TEXT, price TEXT, purchase_way TEXT, planting TEXT, environment_id TEXT, location TEXT, companion_start TEXT, purchase_date TEXT, description TEXT, photos TEXT, custom_water INTEGER, custom_fert INTEGER, custom_repot INTEGER, memorialized INTEGER, memorial_type TEXT, memorial_date TEXT, memorial_note TEXT, companion_snapshot TEXT, created_at INTEGER, updated_at INTEGER)'
    );
    await PlantRepository.store.executeSql(
      'CREATE TABLE IF NOT EXISTS care_records (id TEXT PRIMARY KEY, plant_id TEXT, type TEXT, date TEXT, content TEXT, photo TEXT, created_at INTEGER)'
    );
    await PlantRepository.seedEnvironments();
    await PlantRepository.reload();
    PlantRepository.lastError = '';
    PlantRepository.notify();
  }

  private static db(): relationalStore.RdbStore {
    if (PlantRepository.store === null) {
      throw new Error('本地数据库尚未就绪');
    }
    return PlantRepository.store;
  }

  private static notify(): void {
    const current = AppStorage.get<number>('revision');
    const next = (current === undefined ? 0 : current) + 1;
    AppStorage.setOrCreate('revision', next);
  }

  private static async seedEnvironments(): Promise<void> {
    const result = await PlantRepository.db().query(new relationalStore.RdbPredicates('environments'), ['id']);
    const count = result.rowCount;
    result.close();
    if (count > 0) return;
    const defaults = defaultEnvironments();
    for (let i = 0; i < defaults.length; i++) {
      await PlantRepository.insertEnv(defaults[i]);
    }
  }

  static async reload(): Promise<void> {
    const bundle = new Bundle();
    const envResult = await PlantRepository.db().query(new relationalStore.RdbPredicates('environments'));
    while (envResult.goToNextRow()) {
      bundle.envs.push(PlantRepository.readEnv(envResult));
    }
    envResult.close();
    bundle.envs.sort((a: Environment, b: Environment): number => a.sortOrder - b.sortOrder);

    const plantResult = await PlantRepository.db().query(new relationalStore.RdbPredicates('plants'));
    while (plantResult.goToNextRow()) {
      bundle.plants.push(PlantRepository.readPlant(plantResult));
    }
    plantResult.close();

    const recordResult = await PlantRepository.db().query(new relationalStore.RdbPredicates('care_records'));
    while (recordResult.goToNextRow()) {
      const record = PlantRepository.readRecord(recordResult);
      for (let i = 0; i < bundle.plants.length; i++) {
        if (bundle.plants[i].id === record.plantId) {
          bundle.plants[i].records.push(record);
          break;
        }
      }
    }
    recordResult.close();

    for (let i = 0; i < bundle.plants.length; i++) {
      const records = bundle.plants[i].records;
      records.sort((a: CareRecord, b: CareRecord): number => {
        if (a.date === b.date) return b.createdAt - a.createdAt;
        return a.date < b.date ? 1 : -1;
      });
    }
    bundle.plants.sort((a: Plant, b: Plant): number => b.createdAt - a.createdAt);
    PlantRepository.bundle = bundle;
  }

  private static readEnv(result: relationalStore.ResultSet): Environment {
    const env = new Environment();
    env.id = cellString(result, 'id');
    env.name = cellString(result, 'name');
    env.lightIntensity = cellString(result, 'light_intensity');
    env.lightHours = cellString(result, 'light_hours');
    env.sortOrder = cellLong(result, 'sort_order');
    return env;
  }

  private static readPlant(result: relationalStore.ResultSet): Plant {
    const plant = new Plant();
    plant.id = cellString(result, 'id');
    plant.name = cellString(result, 'name');
    plant.variety = cellString(result, 'variety');
    plant.status = cellString(result, 'status');
    plant.price = cellString(result, 'price');
    plant.purchaseWay = cellString(result, 'purchase_way');
    plant.planting = cellString(result, 'planting');
    plant.environmentId = cellString(result, 'environment_id');
    plant.location = cellString(result, 'location');
    plant.companionStart = cellString(result, 'companion_start');
    plant.purchaseDate = cellString(result, 'purchase_date');
    plant.description = cellString(result, 'description');
    plant.photos = decodeList(cellString(result, 'photos'));
    plant.customWaterInterval = cellLong(result, 'custom_water');
    plant.customFertInterval = cellLong(result, 'custom_fert');
    plant.customRepotInterval = cellLong(result, 'custom_repot');
    plant.memorialized = cellLong(result, 'memorialized') === 1;
    plant.memorialType = cellString(result, 'memorial_type');
    plant.memorialDate = cellString(result, 'memorial_date');
    plant.memorialNote = cellString(result, 'memorial_note');
    plant.companionSnapshot = cellString(result, 'companion_snapshot');
    plant.createdAt = cellLong(result, 'created_at');
    plant.updatedAt = cellLong(result, 'updated_at');
    return plant;
  }

  private static readRecord(result: relationalStore.ResultSet): CareRecord {
    const record = new CareRecord();
    record.id = cellString(result, 'id');
    record.plantId = cellString(result, 'plant_id');
    record.type = cellString(result, 'type');
    record.date = cellString(result, 'date');
    record.content = cellString(result, 'content');
    record.photo = cellString(result, 'photo');
    record.createdAt = cellLong(result, 'created_at');
    return record;
  }

  private static envBucket(env: Environment): relationalStore.ValuesBucket {
    return {
      'id': env.id,
      'name': env.name,
      'light_intensity': env.lightIntensity,
      'light_hours': env.lightHours,
      'sort_order': env.sortOrder
    };
  }

  private static plantBucket(plant: Plant): relationalStore.ValuesBucket {
    return {
      'id': plant.id,
      'name': plant.name,
      'variety': plant.variety,
      'status': plant.status,
      'price': plant.price,
      'purchase_way': plant.purchaseWay,
      'planting': plant.planting,
      'environment_id': plant.environmentId,
      'location': plant.location,
      'companion_start': plant.companionStart,
      'purchase_date': plant.purchaseDate,
      'description': plant.description,
      'photos': encodeList(plant.photos),
      'custom_water': plant.customWaterInterval,
      'custom_fert': plant.customFertInterval,
      'custom_repot': plant.customRepotInterval,
      'memorialized': plant.memorialized ? 1 : 0,
      'memorial_type': plant.memorialType,
      'memorial_date': plant.memorialDate,
      'memorial_note': plant.memorialNote,
      'companion_snapshot': plant.companionSnapshot,
      'created_at': plant.createdAt,
      'updated_at': plant.updatedAt
    };
  }

  private static recordBucket(record: CareRecord): relationalStore.ValuesBucket {
    return {
      'id': record.id,
      'plant_id': record.plantId,
      'type': record.type,
      'date': record.date,
      'content': record.content,
      'photo': record.photo,
      'created_at': record.createdAt
    };
  }

  private static async insertEnv(env: Environment): Promise<void> {
    await PlantRepository.db().insert('environments', PlantRepository.envBucket(env));
  }

  private static async upsertEnv(env: Environment): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('environments');
    predicates.equalTo('id', env.id);
    const changed = await PlantRepository.db().update(PlantRepository.envBucket(env), predicates);
    if (changed === 0) await PlantRepository.insertEnv(env);
  }

  private static async upsertPlant(plant: Plant): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('plants');
    predicates.equalTo('id', plant.id);
    const changed = await PlantRepository.db().update(PlantRepository.plantBucket(plant), predicates);
    if (changed === 0) {
      await PlantRepository.db().insert('plants', PlantRepository.plantBucket(plant));
    }
  }

  private static findPlant(id: string): Plant | null {
    const plants = PlantRepository.bundle.plants;
    for (let i = 0; i < plants.length; i++) {
      if (plants[i].id === id) return plants[i];
    }
    return null;
  }

  private static async finish(): Promise<void> {
    await PlantRepository.reload();
    PlantRepository.notify();
  }

  static async saveEnv(env: Environment): Promise<void> {
    const next = new Environment();
    next.id = env.id.length > 0 ? env.id : newId('env');
    next.name = env.name.trim();
    next.lightIntensity = env.lightIntensity.trim();
    next.lightHours = env.lightHours.trim();
    if (next.name.length === 0) throw new Error('请填写环境名称');
    if (env.id.length === 0) {
      let maxOrder = 0;
      const envs = PlantRepository.bundle.envs;
      for (let i = 0; i < envs.length; i++) {
        if (envs[i].sortOrder > maxOrder) maxOrder = envs[i].sortOrder;
      }
      next.sortOrder = maxOrder + 1;
    } else {
      next.sortOrder = env.sortOrder;
    }
    await PlantRepository.upsertEnv(next);
    await PlantRepository.finish();
  }

  static async deleteEnv(id: string): Promise<void> {
    const plants = PlantRepository.bundle.plants;
    for (let i = 0; i < plants.length; i++) {
      if (plants[i].environmentId === id) {
        const plant = plants[i];
        plant.environmentId = '';
        plant.updatedAt = Date.now();
        await PlantRepository.upsertPlant(plant);
      }
    }
    const predicates = new relationalStore.RdbPredicates('environments');
    predicates.equalTo('id', id);
    await PlantRepository.db().delete(predicates);
    await PlantRepository.finish();
  }

  static async savePlant(plant: Plant): Promise<void> {
    const name = plant.name.trim();
    if (name.length === 0) throw new Error('请填写植物名称');
    const previous = PlantRepository.findPlant(plant.id);
    const now = Date.now();
    const next = plant;
    next.name = name;
    if (next.companionStart.length === 0) next.companionStart = next.purchaseDate;
    if (next.id.length === 0) {
      next.id = newId('plant');
      next.createdAt = now;
    } else if (previous !== null && next.createdAt === 0) {
      next.createdAt = previous.createdAt;
    }
    next.updatedAt = now;
    if (next.status.length === 0) next.status = '健康';
    await PlantRepository.upsertPlant(next);
    if (previous !== null) {
      for (let i = 0; i < previous.photos.length; i++) {
        const oldPhoto = previous.photos[i];
        if (next.photos.indexOf(oldPhoto) < 0) deleteIfOwned(oldPhoto);
      }
    }
    await PlantRepository.finish();
  }

  static async deletePlant(id: string): Promise<void> {
    const previous = PlantRepository.findPlant(id);
    const recordPredicates = new relationalStore.RdbPredicates('care_records');
    recordPredicates.equalTo('plant_id', id);
    await PlantRepository.db().delete(recordPredicates);
    const plantPredicates = new relationalStore.RdbPredicates('plants');
    plantPredicates.equalTo('id', id);
    await PlantRepository.db().delete(plantPredicates);
    if (previous !== null) {
      for (let i = 0; i < previous.photos.length; i++) deleteIfOwned(previous.photos[i]);
      for (let i = 0; i < previous.records.length; i++) deleteIfOwned(previous.records[i].photo);
    }
    await PlantRepository.finish();
  }

  static async saveRecord(record: CareRecord): Promise<void> {
    const plant = PlantRepository.findPlant(record.plantId);
    if (plant === null) throw new Error('植物不存在或已被删除');
    if (plant.memorialized) throw new Error('请先恢复植物再添加记录');
    if (record.type.length === 0) throw new Error('请选择养护类型');
    if (record.date.length === 0) throw new Error('请选择日期');
    const next = record;
    const previousPhoto = PlantRepository.findRecordPhoto(plant, record.id);
    if (next.id.length === 0) {
      next.id = newId('rec');
      next.createdAt = Date.now();
    }
    const predicates = new relationalStore.RdbPredicates('care_records');
    predicates.equalTo('id', next.id);
    const changed = await PlantRepository.db().update(PlantRepository.recordBucket(next), predicates);
    if (changed === 0) {
      await PlantRepository.db().insert('care_records', PlantRepository.recordBucket(next));
    }
    if (previousPhoto.length > 0 && previousPhoto !== next.photo) deleteIfOwned(previousPhoto);
    await PlantRepository.finish();
  }

  private static findRecordPhoto(plant: Plant, recordId: string): string {
    if (recordId.length === 0) return '';
    for (let i = 0; i < plant.records.length; i++) {
      if (plant.records[i].id === recordId) return plant.records[i].photo;
    }
    return '';
  }

  static async deleteRecord(id: string): Promise<void> {
    let photo = '';
    const plants = PlantRepository.bundle.plants;
    for (let i = 0; i < plants.length; i++) {
      const records = plants[i].records;
      for (let r = 0; r < records.length; r++) {
        if (records[r].id === id) photo = records[r].photo;
      }
    }
    const predicates = new relationalStore.RdbPredicates('care_records');
    predicates.equalTo('id', id);
    await PlantRepository.db().delete(predicates);
    deleteIfOwned(photo);
    await PlantRepository.finish();
  }

  static async memorialize(plantId: string, type: string, date: string, note: string, companion: string): Promise<void> {
    const plant = PlantRepository.findPlant(plantId);
    if (plant === null) throw new Error('植物不存在或已被删除');
    if (date.length === 0) throw new Error('请选择日期');
    plant.memorialized = true;
    plant.memorialType = type;
    plant.memorialDate = date;
    plant.memorialNote = note.trim();
    plant.companionSnapshot = companion;
    plant.updatedAt = Date.now();
    await PlantRepository.upsertPlant(plant);
    await PlantRepository.finish();
  }

  static async restorePlant(plantId: string): Promise<void> {
    const plant = PlantRepository.findPlant(plantId);
    if (plant === null) throw new Error('植物不存在或已被删除');
    plant.memorialized = false;
    plant.memorialType = '';
    plant.memorialDate = '';
    plant.memorialNote = '';
    plant.companionSnapshot = '';
    plant.updatedAt = Date.now();
    await PlantRepository.upsertPlant(plant);
    await PlantRepository.finish();
  }

  static async importAll(envs: Environment[], plants: Plant[]): Promise<void> {
    const oldPhotos: string[] = [];
    for (let i = 0; i < plants.length; i++) {
      const existing = PlantRepository.findPlant(plants[i].id);
      if (existing === null) continue;
      for (let p = 0; p < existing.photos.length; p++) oldPhotos.push(existing.photos[p]);
      for (let r = 0; r < existing.records.length; r++) {
        if (existing.records[r].photo.length > 0) oldPhotos.push(existing.records[r].photo);
      }
    }
    const db = PlantRepository.db();
    db.beginTransaction();
    try {
      for (let i = 0; i < envs.length; i++) {
        await PlantRepository.upsertEnv(envs[i]);
      }
      for (let i = 0; i < plants.length; i++) {
        const plant = plants[i];
        const recordPredicates = new relationalStore.RdbPredicates('care_records');
        recordPredicates.equalTo('plant_id', plant.id);
        await db.delete(recordPredicates);
        await PlantRepository.upsertPlant(plant);
        for (let r = 0; r < plant.records.length; r++) {
          await db.insert('care_records', PlantRepository.recordBucket(plant.records[r]));
        }
      }
      db.commit();
    } catch (err) {
      db.rollBack();
      throw err instanceof Error ? err : new Error('导入失败');
    }
    for (let i = 0; i < oldPhotos.length; i++) deleteIfOwned(oldPhotos[i]);
    await PlantRepository.finish();
  }
}
