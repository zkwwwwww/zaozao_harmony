export class Theme {
  static readonly primary: string = '#2E7D5B';
  static readonly primaryDark: string = '#1F5C42';
  static readonly bg: string = '#F4F7F5';
  static readonly card: string = '#FFFFFF';
  static readonly text: string = '#1C2B24';
  static readonly sub: string = '#6D7F75';
  static readonly line: string = '#E4EEE8';
  static readonly danger: string = '#C0554F';
  static readonly amber: string = '#C4841D';
  static readonly cream: string = '#F6F1E7';
  static readonly sprout: string = '#E7F4EC';
  static readonly hint: string = '#A0B0A6';
}

export class CareRecord {
  id: string = '';
  plantId: string = '';
  type: string = '';
  date: string = '';
  content: string = '';
  photo: string = '';
  createdAt: number = 0;
}

export class Environment {
  id: string = '';
  name: string = '';
  lightIntensity: string = '';
  lightHours: string = '';
  sortOrder: number = 0;
}

export class Plant {
  id: string = '';
  name: string = '';
  variety: string = '';
  status: string = '健康';
  price: string = '';
  purchaseWay: string = '';
  planting: string = '';
  environmentId: string = '';
  location: string = '';
  companionStart: string = '';
  purchaseDate: string = '';
  description: string = '';
  photos: string[] = [];
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
  records: CareRecord[] = [];
}

export class Bundle {
  plants: Plant[] = [];
  envs: Environment[] = [];
}

export class NavParam {
  plantId: string = '';
  careType: string = '';
  envId: string = '';
  recordId: string = '';
}

export class PlantCard {
  id: string = '';
  name: string = '';
  variety: string = '';
  status: string = '';
  price: string = '';
  planting: string = '';
  envName: string = '';
  photo: string = '';
  waterText: string = '';
  waterTone: string = 'none';
}

export class TaskRow {
  key: string = '';
  plantId: string = '';
  plantName: string = '';
  photo: string = '';
  type: string = '';
  label: string = '';
  due: string = '';
  dueText: string = '';
  overdue: boolean = false;
}

export class HomeStats {
  count: number = 0;
  totalPrice: string = '0';
  waterToday: number = 0;
  overdue: number = 0;
}

export class EnvCard {
  id: string = '';
  name: string = '';
  lightIntensity: string = '';
  lightHours: string = '';
  count: number = 0;
}

export class LuxRow {
  label: string = '';
  value: string = '';
}
