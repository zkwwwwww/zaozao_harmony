import { TaskRow, Theme } from '../model/types';
import { seasonWaterText } from '../common/reminder';
import { openPage, navigationStack } from '../common/route';
import { buildTasks } from '../common/viewmodel';
import { PlantRepository } from '../store/PlantRepository';
import { EmptyState, PageHeader } from '../components/Chrome';

@Component
export struct ReminderTab {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('revision') @Watch('onRevision') revision: number = 0;
  @State season: string = '';
  @State tasks: TaskRow[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  onRevision(): void {
    this.refresh();
  }

  private refresh(): void {
    this.season = seasonWaterText();
    this.tasks = buildTasks(PlantRepository.current());
  }

  build() {
    Column() {
      PageHeader({ title: '养护提醒' })
      Scroll() {
        Column() {
          Text(this.season + '。施肥默认 30 天，换盆默认 365 天，都可以在植物里单独改。')
            .fontSize(13)
            .fontColor(Theme.sub)
            .lineHeight(20)
            .width('100%')
          Text('这里显示未来 14 天内的事项，以及全部逾期事项。点完成后会记一条养护。')
            .fontSize(13)
            .fontColor(Theme.sub)
            .lineHeight(20)
            .margin({ top: 6 })
            .width('100%')

          if (this.tasks.length === 0) {
            EmptyState({
              title: '近期没有待办',
              message: '给植物填上购买日或陪伴起始日后，浇水、施肥和换盆就会出现在这里。'
            })
          }

          ForEach(this.tasks, (task: TaskRow) => {
            Row() {
              Column() {
                Text(task.plantName)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.text)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(task.label + ' · ' + task.due)
                  .fontSize(13)
                  .fontColor(Theme.sub)
                  .margin({ top: 4 })
                Text(task.dueText)
                  .fontSize(13)
                  .fontColor(task.overdue ? Theme.danger : Theme.primary)
                  .margin({ top: 4 })
              }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => {
        openPage(this.pathStack, 'PlantDetail', task.plantId, '', '', '');
      })

      Text('完成')
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor(Theme.primary)
                .borderRadius(16)
                .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                .onClick(() => {
                  openPage(this.pathStack, 'NoteEdit', task.plantId, task.label, '', '');
                })
            }
            .width('100%')
            .padding(14)
            .margin({ top: 12 })
    .backgroundColor(Color.White)
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
  }, (task: TaskRow) => task.key)
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
