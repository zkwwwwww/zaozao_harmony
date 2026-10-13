import { HomeStats, PlantCard, TaskRow, Theme } from '../model/types';
import { STATUS_OPTIONS } from '../common/constants';
import { money } from '../common/format';
import { seasonWaterText } from '../common/reminder';
import { openPage, navigationStack } from '../common/route';
import { buildCards, buildStats, buildTasks, filterCards } from '../common/viewmodel';
import { PlantRepository } from '../store/PlantRepository';
import { EmptyState, PlantCover, SectionTitle, Tag } from '../components/Chrome';

@Component
export struct HomeTab {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('topInset') topInset: number = 36;
  @StorageLink('revision') @Watch('onRevision') revision: number = 0;
  @State season: string = '';
  @State stats: HomeStats = new HomeStats();
  @State tasks: TaskRow[] = [];
  @State cards: PlantCard[] = [];
  @State visible: PlantCard[] = [];
  @State keyword: string = '';
  @State status: string = '';
  @State pricesVisible: boolean = false;
  @State loadError: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  onRevision(): void {
    this.refresh();
  }

  private refresh(): void {
    this.loadError = PlantRepository.lastError;
    this.season = seasonWaterText();
    const bundle = PlantRepository.current();
    this.cards = buildCards(bundle);
    this.tasks = buildTasks(bundle);
    this.stats = buildStats(bundle, this.tasks);
    this.visible = filterCards(this.cards, this.keyword, this.status);
  }

  private toneOf(tone: string): string {
    if (tone === 'overdue') return Theme.danger;
    if (tone === 'today') return Theme.amber;
    if (tone === 'soon') return Theme.primary;
    return Theme.sub;
  }

  @Builder
  stat(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .maxLines(1)
      Text(label)
        .fontSize(12)
        .fontColor('#D7EBE1')
        .margin({ top: 2 })
    }
    .width('100%')
    .padding(10)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#1AFFFFFF')
    .borderRadius(12)
  }

  @Builder
  chip(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.status === value ? Color.White : Theme.primaryDark)
      .backgroundColor(this.status === value ? Theme.primary : Theme.sprout)
      .borderRadius(14)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .onClick(() => {
        this.status = value;
        this.visible = filterCards(this.cards, this.keyword, this.status);
      })
  }

  @Builder
  taskRow(task: TaskRow) {
    Row() {
      Column() {
        Text(task.plantName + ' · ' + task.label)
          .fontSize(15)
          .fontColor(Theme.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(task.due + '  ' + task.dueText)
          .fontSize(12)
          .fontColor(task.overdue ? Theme.danger : Theme.sub)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => {
        openPage(this.pathStack, 'PlantDetail', task.plantId, '', '', '');
      })

      Text('完成')
        .fontSize(13)
        .fontColor(Theme.primary)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .borderRadius(14)
        .backgroundColor(Theme.sprout)
        .onClick(() => {
          openPage(this.pathStack, 'NoteEdit', task.plantId, task.label, '', '');
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .margin({ bottom: 8 })
  }

  @Builder
  plantCard(card: PlantCard) {
    Column() {
      Stack({ alignContent: Alignment.TopEnd }) {
        PlantCover({ photo: card.photo })
          .width('100%')
          .height(132)
        Tag({ text: card.status, tone: 'green' })
          .margin({ top: 8, right: 8 })
      }
      .width('100%')
      .height(132)

      Column() {
        Text(card.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text((card.variety.length > 0 ? card.variety + ' · ' : '') + card.envName)
          .fontSize(12)
          .fontColor(Theme.sub)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
        if (card.waterText.length > 0) {
          Text(card.waterText)
            .fontSize(12)
            .fontColor(this.toneOf(card.waterTone))
            .margin({ top: 6 })
        }
        if (this.pricesVisible && card.price.length > 0) {
          Text('¥' + money(card.price))
            .fontSize(12)
            .fontColor(Theme.sub)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding(10)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
    .clip(true)
    .onClick(() => {
      openPage(this.pathStack, 'PlantDetail', card.id, '', '', '');
    })
  }

  build() {
    Column() {
      Column() {
        Row() {
          Text('植早早')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
          Text('添加')
            .fontSize(15)
            .fontColor(Color.White)
            .onClick(() => {
              openPage(this.pathStack, 'PlantEdit', '', '', '', '');
            })
        }
        .width('100%')

        Text(this.season)
          .fontSize(12)
          .fontColor('#D7EBE1')
          .margin({ top: 6 })
          .width('100%')

        GridRow({ columns: 2, gutter: 8 }) {
          GridCol({ span: 1 }) {
            this.stat(this.stats.count + '', '植物')
          }
          GridCol({ span: 1 }) {
            this.stat(this.pricesVisible ? '¥' + this.stats.totalPrice : '•••', '总投入')
          }
          GridCol({ span: 1 }) {
            this.stat(this.stats.waterToday + '', '今日浇水')
          }
          GridCol({ span: 1 }) {
            this.stat(this.stats.overdue + '', '逾期')
          }
        }
        .margin({ top: 12 })
        .width('100%')

        Text(this.pricesVisible ? '隐藏金额' : '显示金额')
          .fontSize(12)
          .fontColor('#D7EBE1')
          .margin({ top: 8 })
          .onClick(() => {
            this.pricesVisible = !this.pricesVisible;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({
        top: this.topInset + 12,
        left: 16,
        right: 16,
        bottom: 16
      })
      .backgroundColor(Theme.primary)

      if (this.loadError.length > 0) {
        Text(this.loadError)
          .fontSize(13)
          .fontColor(Theme.danger)
          .padding(16)
      }

      Scroll() {
        Column() {
          TextInput({ text: this.keyword, placeholder: '搜索名称、品种或环境' })
            .height(42)
            .fontSize(15)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .placeholderColor(Theme.hint)
            .onChange((value: string) => {
              this.keyword = value;
              this.visible = filterCards(this.cards, this.keyword, this.status);
            })

          Scroll() {
            Row({ space: 8 }) {
              this.chip('全部', '')
              ForEach(STATUS_OPTIONS, (item: string) => {
                this.chip(item, item)
              }, (item: string) => item)
            }
            .padding({ top: 10, bottom: 2 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')

          GridRow({
            columns: { xs: 1, sm: 1, md: 12, lg: 12 },
            gutter: 16,
            breakpoints: {
              value: ['320vp', '600vp', '840vp'],
              reference: BreakpointsReference.WindowSize
            }
          }) {
            GridCol({ span: { xs: 1, sm: 1, md: 4, lg: 4 } }) {
              Column() {
                SectionTitle({
                  title: '近期待办',
                  extra: '全部',
                  onExtra: () => {
                    AppStorage.setOrCreate('currentTab', 2);
                  }
                })
                if (this.tasks.length === 0) {
                  Text('这 14 天里没有待办，逾期的事项也会出现在这里。')
                    .fontSize(13)
                    .fontColor(Theme.sub)
                    .width('100%')
                } else {
                  ForEach(this.previewTasks(), (task: TaskRow) => {
                    this.taskRow(task)
                  }, (task: TaskRow) => task.key)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            GridCol({ span: { xs: 1, sm: 1, md: 8, lg: 8 } }) {
              Column() {
                SectionTitle({ title: '我的植物' })
                if (this.cards.length === 0) {
                  EmptyState({
                    title: '还没有植物',
                    message: '记下第一株。浇水会按季节帮你算：春、秋 10 天，夏 5 天，冬 15 天。'
                  })
                } else if (this.visible.length === 0) {
                  EmptyState({ title: '没有符合的植物', message: '换个名称或状态再看看。' })
                } else {
                  GridRow({
                    columns: { xs: 1, sm: 2, md: 2, lg: 3 },
                    gutter: 12,
                    breakpoints: { reference: BreakpointsReference.ComponentSize }
                  }) {
                    ForEach(this.visible, (card: PlantCard) => {
                      GridCol({ span: 1 }) {
                        this.plantCard(card)
                      }
                    }, (card: PlantCard) => card.id)
                  }
                  .width('100%')
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }

  private previewTasks(): TaskRow[] {
    const list: TaskRow[] = [];
    const limit = this.tasks.length < 5 ? this.tasks.length : 5;
    for (let i = 0; i < limit; i++) list.push(this.tasks[i]);
    return list;
  }
}
