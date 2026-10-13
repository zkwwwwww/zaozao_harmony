import { CareRecord, TaskRow, Theme } from '../model/types';
import { CARE_TYPES, MEMORIAL_TYPES } from '../common/constants';
import { companionText, errorText, fmtParts, money, today } from '../common/format';
import { plantTasks } from '../common/reminder';
import { openPage, takeRoute, navigationStack } from '../common/route';
import { findEnv, findPlant } from '../common/viewmodel';
import { PlantRepository } from '../store/PlantRepository';
import { EmptyState, PageHeader, PlantCover, PrimaryButton, Tag } from '../components/Chrome';

@Component
export struct PlantDetail {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('bottomInset') bottomInset: number = 0;
  @StorageLink('revision') @Watch('onRevision') revision: number = 0;
  @State plantId: string = '';
  @State missing: boolean = false;
  @State name: string = '';
  @State variety: string = '';
  @State status: string = '';
  @State price: string = '';
  @State purchaseWay: string = '';
  @State planting: string = '';
  @State location: string = '';
  @State description: string = '';
  @State envText: string = '';
  @State companion: string = '';
  @State companionStart: string = '';
  @State purchaseDate: string = '';
  @State photos: string[] = [];
  @State records: CareRecord[] = [];
  @State tasks: TaskRow[] = [];
  @State memorialized: boolean = false;
  @State memorialType: string = '';
  @State memorialDateText: string = '';
  @State memorialNote: string = '';
  @State companionSnapshot: string = '';
  @State showMemorial: boolean = false;
  @State draftType: string = '送人';
  @State draftDate: string = '';
  @State draftNote: string = '';
  @State preview: string = '';
  @State busy: boolean = false;

  aboutToAppear(): void {
    const route = takeRoute();
    this.plantId = route.plantId;
    this.draftDate = today();
    this.refresh();
  }

  onRevision(): void {
    this.refresh();
  }

  private refresh(): void {
    const bundle = PlantRepository.current();
    const plant = findPlant(bundle.plants, this.plantId);
    if (plant === null) {
      this.missing = true;
      return;
    }
    this.missing = false;
    this.name = plant.name;
    this.variety = plant.variety;
    this.status = plant.status;
    this.price = plant.price;
    this.purchaseWay = plant.purchaseWay;
    this.planting = plant.planting;
    this.location = plant.location;
    this.description = plant.description;
    this.companionStart = plant.companionStart;
    this.purchaseDate = plant.purchaseDate;
    this.photos = plant.photos;
    this.records = plant.records;
    this.memorialized = plant.memorialized;
    this.memorialType = plant.memorialType;
    this.memorialDateText = plant.memorialDate;
    this.memorialNote = plant.memorialNote;
    this.companionSnapshot = plant.companionSnapshot;
    const start = plant.companionStart.length > 0 ? plant.companionStart : plant.purchaseDate;
    this.companion = companionText(start);
    const env = findEnv(bundle.envs, plant.environmentId);
    if (env === null) {
      this.envText = '';
    } else {
      const lux = env.lightIntensity.length > 0 ? env.lightIntensity + ' lux' : '光照未填';
      const hours = env.lightHours.length > 0 ? '每天 ' + env.lightHours + ' 小时' : '';
      this.envText = env.name + ' · ' + lux + (hours.length > 0 ? ' · ' + hours : '');
    }
    const items = plant.memorialized ? [] : plantTasks(plant, 14);
    const rows: TaskRow[] = [];
    for (let i = 0; i < items.length; i++) {
      const row = new TaskRow();
      row.key = items[i].type;
      row.plantId = plant.id;
      row.label = items[i].label;
      row.due = items[i].due;
      row.dueText = items[i].dueText;
      row.overdue = items[i].overdue;
      row.type = items[i].type;
      rows.push(row);
    }
    this.tasks = rows;
  }

  private toast(text: string): void {
    this.getUIContext().getPromptAction().showToast({ message: text });
  }

  private addNote(type: string): void {
    if (this.memorialized) {
      this.toast('请先恢复植物再添加记录');
      return;
    }
    openPage(this.pathStack, 'NoteEdit', this.plantId, type, '', '');
  }

  private askMemorial(): void {
    this.getUIContext().getPromptAction().showActionSheet({
      title: '建立纪念碑',
      sheets: [{ title: MEMORIAL_TYPES[0] }, { title: MEMORIAL_TYPES[1] }],
      onAccept: (index: number) => {
        this.draftType = index === 1 ? MEMORIAL_TYPES[1] : MEMORIAL_TYPES[0];
        this.draftDate = today();
        this.draftNote = '';
        this.showMemorial = true;
      }
    });
  }

  private saveMemorial(): void {
    if (this.busy) return;
    if (this.draftDate.length === 0) {
      this.toast('请选择日期');
      return;
    }
    this.busy = true;
    const start = this.companionStart.length > 0 ? this.companionStart : this.purchaseDate;
    PlantRepository.memorialize(this.plantId, this.draftType, this.draftDate, this.draftNote, companionText(start))
      .then(() => {
        this.busy = false;
        this.showMemorial = false;
        this.toast('已建立纪念碑');
      })
      .catch((err: Object) => {
        this.busy = false;
        this.toast(errorText(err));
      });
  }

  private restore(): void {
    AlertDialog.show({
      title: '恢复植物',
      message: '会回到主页的活跃列表，并去掉纪念碑。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '恢复',
        fontColor: Theme.primary,
        action: () => {
          PlantRepository.restorePlant(this.plantId).then(() => {
            this.toast('已恢复');
          }).catch((err: Object) => {
            this.toast(errorText(err));
          });
        }
      }
    });
  }

  private removePlant(): void {
    AlertDialog.show({
      title: '删除植物',
      message: '将删除「' + this.name + '」及其全部养护记录，且无法恢复。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: Theme.danger,
        action: () => {
          PlantRepository.deletePlant(this.plantId).then(() => {
            this.toast('已删除');
            this.pathStack.pop();
          }).catch((err: Object) => {
            this.toast(errorText(err));
          });
        }
      }
    });
  }

  private removeRecord(record: CareRecord): void {
    AlertDialog.show({
      title: '删除记录',
      message: '删除这条' + record.type + '记录后，相关提醒会按剩下的记录重算。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: Theme.danger,
        action: () => {
          PlantRepository.deleteRecord(record.id).catch((err: Object) => {
            this.toast(errorText(err));
          });
        }
      }
    });
  }

  @Builder
  info(label: string, value: string) {
    if (value.length > 0) {
      Row() {
        Text(label)
          .width(88)
          .fontSize(14)
          .fontColor(Theme.sub)
        Text(value)
          .layoutWeight(1)
          .fontSize(14)
          .fontColor(Theme.text)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ top: 7, bottom: 7 })
    }
  }

  build() {
    Stack() {
      Column() {
        PageHeader({
          title: '植物',
          showBack: true,
          action: this.missing ? '' : '编辑',
          onAction: () => {
            openPage(this.pathStack, 'PlantEdit', this.plantId, '', '', '');
          }
        })
        if (this.missing) {
          EmptyState({ title: '找不到这株植物', message: '它可能已经被删除。' })
        } else {
          Scroll() {
            Column() {
              if (this.photos.length > 0) {
                Swiper() {
                  ForEach(this.photos, (photo: string) => {
                    PlantCover({ photo: photo })
                      .width('100%')
                      .height(240)
                      .onClick(() => {
                        this.preview = photo;
                      })
                  }, (photo: string) => photo)
                }
                .width('100%')
                .height(240)
                .indicator(true)
                .index(0)
              } else {
                PlantCover({ photo: '' })
                  .width('100%')
                  .height(160)
              }

              Column() {
                Text(this.name)
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.text)
                  .width('100%')
                Row() {
                  if (this.status.length > 0) {
                    Tag({ text: this.status, tone: 'green' })
                  }
                  Text(this.companion)
                    .fontSize(13)
                    .fontColor(Theme.sub)
                    .margin({ left: 8 })
                }
                .margin({ top: 8 })
                .width('100%')

                if (this.memorialized) {
                  Tag({
                    text: (this.memorialType.length > 0 ? this.memorialType : '纪念') + ' · ' + this.memorialDateText,
                    tone: this.memorialType === '送人' ? 'blue' : 'gray'
                  })
                    .margin({ top: 8 })
                  if (this.companionSnapshot.length > 0) {
                    Text('纪念时的陪伴：' + this.companionSnapshot)
                      .fontSize(13)
                      .fontColor(Theme.sub)
                      .margin({ top: 8 })
                      .width('100%')
                  }
                  if (this.memorialNote.length > 0) {
                    Text(this.memorialNote)
                      .fontSize(14)
                      .fontColor(Theme.text)
                      .margin({ top: 6 })
                      .width('100%')
                  }
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16 })
              .alignItems(HorizontalAlign.Start)

              Column() {
                this.info('品种', this.variety)
                this.info('价格', this.price.length > 0 ? '¥' + money(this.price) : '')
                this.info('购买途径', this.purchaseWay)
                this.info('种植形式', this.planting)
                this.info('环境', this.envText)
                this.info('位置', this.location)
                this.info('购买日期', this.purchaseDate)
                this.info('陪伴起始', this.companionStart)
                this.info('备注', this.description)
              }
              .width('100%')
              .padding(16)
              .margin({ left: 16, right: 16, top: 12 })
              .backgroundColor(Color.White)
              .borderRadius(16)
              .alignItems(HorizontalAlign.Start)

              if (!this.memorialized) {
                Text('记一笔')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.text)
                  .margin({ top: 18, left: 16 })
                  .width('100%')
                Flex({ wrap: FlexWrap.Wrap }) {
                  ForEach(CARE_TYPES, (item: string) => {
                    Text(item)
                      .fontSize(14)
                      .fontColor(Theme.primaryDark)
                      .backgroundColor(Color.White)
                      .borderRadius(16)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .margin({ top: 8, right: 8 })
                      .onClick(() => {
                        this.addNote(item);
                      })
                  }, (item: string) => item)
                }
                .width('100%')
                .padding({ left: 16, right: 16 })

                Text('近期提醒')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.text)
                  .margin({ top: 18, left: 16, bottom: 8 })
                  .width('100%')
                if (this.tasks.length === 0) {
                  Text('未来 14 天没有待办。')
                    .fontSize(13)
                    .fontColor(Theme.sub)
                    .margin({ left: 16 })
                    .width('100%')
                }
                ForEach(this.tasks, (task: TaskRow) => {
                  Row() {
                    Text(task.label + ' · ' + task.dueText)
                      .fontSize(14)
                      .fontColor(task.overdue ? Theme.danger : Theme.text)
                      .layoutWeight(1)
                    Text('完成')
                      .fontSize(13)
                      .fontColor(Theme.primary)
                      .onClick(() => {
                        this.addNote(task.label);
                      })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                }, (task: TaskRow) => task.key)
              }

              Text('养护记录')
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.text)
                .margin({ top: 18, left: 16, bottom: 8 })
                .width('100%')
              if (this.records.length === 0) {
                Text('还没有记录。浇水、施肥、修剪、换盆、防治和测量都可以记。')
                  .fontSize(13)
                  .fontColor(Theme.sub)
                  .margin({ left: 16, right: 16 })
                  .width('100%')
              }
              ForEach(this.records, (record: CareRecord) => {
                Column() {
                  Row() {
                    Text(record.type)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.text)
                      .layoutWeight(1)
                    Text(record.date)
                      .fontSize(13)
                      .fontColor(Theme.sub)
                  }
                  .width('100%')
                  if (record.content.length > 0) {
                    Text(record.content)
                      .fontSize(14)
                      .fontColor(Theme.text)
                      .lineHeight(20)
                      .margin({ top: 6 })
                      .width('100%')
                  }
                  if (record.photo.length > 0) {
                    Image(record.photo)
                      .width(88)
                      .height(88)
                      .borderRadius(10)
                      .objectFit(ImageFit.Cover)
                      .margin({ top: 8 })
                      .onClick(() => {
                        this.preview = record.photo;
                      })
                  }
                  Row() {
                    if (!this.memorialized) {
                      Text('编辑')
                        .fontSize(13)
                        .fontColor(Theme.primary)
                        .margin({ top: 8, right: 16 })
                        .onClick(() => {
                          openPage(this.pathStack, 'NoteEdit', this.plantId, record.type, '', record.id);
                        })
                    }
                    Text('删除')
                      .fontSize(13)
                      .fontColor(Theme.danger)
                      .margin({ top: 8 })
                      .onClick(() => {
                        this.removeRecord(record);
                      })
                  }
                  .width('100%')
                }
                .width('100%')
                .padding(14)
                .margin({ left: 16, right: 16, bottom: 10 })
                .backgroundColor(Color.White)
                .borderRadius(16)
                .alignItems(HorizontalAlign.Start)
              }, (record: CareRecord) => record.id)

              Column({ space: 10 }) {
                if (this.memorialized) {
                  PrimaryButton({
                    text: '恢复到主页',
                    onTap: () => {
                      this.restore();
                    }
                  })
                } else {
                  PrimaryButton({
                    text: '建立纪念碑',
                    ghost: true,
                    onTap: () => {
                      this.askMemorial();
                    }
                  })
                }
                PrimaryButton({
                  text: '删除植物',
                  danger: true,
                  onTap: () => {
                    this.removePlant();
                  }
                })
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 8, bottom: this.bottomInset + 24 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .align(Alignment.TopStart)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.bg)

      if (this.showMemorial) {
        Column() {
          Column() {
            Text('纪念 · ' + this.draftType)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.text)
              .width('100%')
            Text(this.draftDate.length > 0 ? this.draftDate : '选择日期')
              .fontSize(16)
              .fontColor(Theme.primary)
              .margin({ top: 16 })
              .onClick(() => {
                this.pickMemorialDate();
              })
            TextArea({ text: this.draftNote, placeholder: '想留下的话，可以不填' })
              .height(90)
              .margin({ top: 12 })
              .backgroundColor(Theme.bg)
              .borderRadius(12)
              .onChange((value: string) => {
                this.draftNote = value;
              })
            Button('保存纪念')
              .width('100%')
              .height(44)
              .margin({ top: 16 })
              .fontColor(Color.White)
              .backgroundColor(Theme.primary)
              .borderRadius(22)
              .onClick(() => {
                this.saveMemorial();
              })
            Text('取消')
              .fontSize(15)
              .fontColor(Theme.sub)
              .margin({ top: 12 })
              .onClick(() => {
                this.showMemorial = false;
              })
          }
          .width('86%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(18)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#66000000')
      }

      if (this.preview.length > 0) {
        Stack() {
          Image(this.preview)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .backgroundColor('#111111')
          Text('关闭')
            .fontSize(16)
            .fontColor(Color.White)
            .margin({ top: 48 })
        }
        .width('100%')
        .height('100%')
        .alignContent(Alignment.TopStart)
        .onClick(() => {
          this.preview = '';
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  private pickMemorialDate(): void {
    const current = this.draftDate.length > 0 ? new Date(this.draftDate + 'T12:00:00') : new Date();
    DatePickerDialog.show({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: current,
      onDateAccept: (value: DatePickerResult) => {
        this.draftDate = fmtParts(value.year, value.month + 1, value.day);
      }
    });
  }
}
