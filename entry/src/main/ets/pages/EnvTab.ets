import { EnvCard, Theme } from '../model/types';
import { openPage, navigationStack } from '../common/route';
import { buildEnvCards } from '../common/viewmodel';
import { PlantRepository } from '../store/PlantRepository';
import { EmptyState, PageHeader } from '../components/Chrome';

@Component
export struct EnvTab {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('revision') @Watch('onRevision') revision: number = 0;
  @State cards: EnvCard[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  onRevision(): void {
    this.refresh();
  }

  private refresh(): void {
    this.cards = buildEnvCards(PlantRepository.current());
  }

  build() {
    Column() {
      PageHeader({
        title: '生长环境',
        action: '新建',
        onAction: () => {
          openPage(this.pathStack, 'EnvironmentEdit', '', '', '', '');
        }
      })
      Scroll() {
        Column() {
          Text('为每个环境记下光照强度（lux）和每天的光照时长。删掉环境后，原来的植物会变成未分类。')
            .fontSize(13)
            .fontColor(Theme.sub)
            .lineHeight(20)
            .width('100%')

          if (this.cards.length === 0) {
            EmptyState({ title: '还没有环境', message: '可以先建一个阳台、窗边或弱光角落。' })
          }

          ForEach(this.cards, (card: EnvCard) => {
            Column() {
              Row() {
                Text(card.name)
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.text)
                  .layoutWeight(1)
                Text(card.count + ' 株')
                  .fontSize(13)
                  .fontColor(Theme.primary)
              }
              .width('100%')

              Text((card.lightIntensity.length > 0 ? card.lightIntensity : '—') + ' lux')
                .fontSize(14)
                .fontColor(Theme.sub)
                .margin({ top: 8 })
                .width('100%')
              Text('每天 ' + (card.lightHours.length > 0 ? card.lightHours : '—') + ' 小时')
                .fontSize(14)
                .fontColor(Theme.sub)
                .margin({ top: 4 })
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .margin({ top: 12 })
            .backgroundColor(Color.White)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
            .onClick(() => {
              openPage(this.pathStack, 'EnvironmentEdit', '', '', card.id, '');
            })
          }, (card: EnvCard) => card.id)
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
