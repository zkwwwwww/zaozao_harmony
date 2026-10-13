const test = require('node:test');
const assert = require('node:assert/strict');
const format = require('./format');
const reminder = require('./reminder');

function plant(overrides) {
  return Object.assign({
    purchaseDate: format.today(),
    companionStart: '',
    records: [],
    customWaterInterval: 5,
    customFertInterval: 30,
    customRepotInterval: 365
  }, overrides);
}

test('invalid calendar dates are rejected', () => {
  assert.equal(format.toDate('2026-02-31'), null);
  assert.equal(format.toDate('2026-13-01'), null);
  assert.equal(format.addDays('2026-02-28', 1), '2026-03-01');
  assert.equal(format.addDays('2024-02-28', 1), '2024-02-29');
  assert.equal(format.addDays('2024-02-28', 2), '2024-03-01');
});

test('season water intervals follow spring summer autumn winter', () => {
  assert.equal(reminder.waterIntervalFor({ customWaterInterval: 0 }, new Date(2026, 3, 1)), 10);
  assert.equal(reminder.waterIntervalFor({ customWaterInterval: 0 }, new Date(2026, 6, 1)), 5);
  assert.equal(reminder.waterIntervalFor({ customWaterInterval: 0 }, new Date(2026, 9, 1)), 10);
  assert.equal(reminder.waterIntervalFor({ customWaterInterval: 0 }, new Date(2026, 0, 15)), 15);
  assert.equal(reminder.waterIntervalFor({ customWaterInterval: 7 }, new Date(2026, 6, 1)), 7);
});

test('nextDueDate uses latest matching record', () => {
  const p = plant({
    records: [
      { type: '浇水', date: '2026-01-02' },
      { type: '浇水', date: '2026-01-05' },
      { type: '施肥', date: '2026-01-08' }
    ]
  });
  assert.equal(reminder.nextDueDate(p, 'water'), '2026-01-10');
  assert.equal(reminder.nextDueDate(p, 'fertilize'), '2026-02-07');
});

test('plantTasks includes upcoming tasks and always keeps overdue tasks', () => {
  const soon = plant({ purchaseDate: format.today(), customWaterInterval: 5 });
  assert.equal(reminder.plantTasks(soon, { upcomingDays: 7 }).some(task => task.type === 'water' && task.dueText === '还有 5 天'), true);

  const distant = plant({ purchaseDate: format.today(), customWaterInterval: 20 });
  assert.equal(reminder.plantTasks(distant, { upcomingDays: 7 }).some(t => t.type === 'water'), false);

  const overdue = plant({
    purchaseDate: format.addDays(format.today(), -20),
    customWaterInterval: 5
  });
  assert.equal(reminder.plantTasks(overdue, { upcomingDays: 0 }).some(t => t.type === 'water' && t.overdue), true);
});

test('plantTasks skips plants without a valid base date', () => {
  assert.deepEqual(reminder.plantTasks(plant({ purchaseDate: '', companionStart: '', records: [] })), []);
});

test('money and companion text', () => {
  assert.equal(format.money(12), '12');
  assert.equal(format.money(12.5), '12.5');
  assert.equal(format.money(12.25), '12.25');
  assert.equal(format.companionText(''), '未设置');
  assert.equal(format.companionText(format.today()), '今天加入');
});
