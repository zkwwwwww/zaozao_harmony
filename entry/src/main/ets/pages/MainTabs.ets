import { Theme } from '../model/types';
import { HomeTab } from './HomeTab';
import { EnvTab } from './EnvTab';
import { ReminderTab } from './ReminderTab';
import { MemorialTab } from './MemorialTab';

@Component
export struct MainTabs {
  @StorageLink('currentTab') @Watch('onTabWanted') currentTab: number = 0;
  @StorageLink('bottomInset') bottomInset: number = 0;
  private controller: TabsController = new TabsController();

  onTabWanted(): void {
    this.controller.changeIndex(this.currentTab);
  }

  @Builder
  tabItem(title: string, index: number) {
    Column() {
      Capsule()
        .width(18)
        .height(3)
        .fill(this.currentTab === index ? Theme.primary : Color.Transparent)
      Text(title)
        .fontSize(12)
        .margin({ top: 4 })
        .fontColor(this.currentTab === index ? Theme.primary : '#8A9B90')
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ bottom: this.bottomInset })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller, index: this.currentTab }) {
      TabContent() {
        HomeTab()
      }.tabBar(this.tabItem('主页', 0))

      TabContent() {
        EnvTab()
      }.tabBar(this.tabItem('环境', 1))

      TabContent() {
        ReminderTab()
      }.tabBar(this.tabItem('提醒', 2))

      TabContent() {
        MemorialTab()
      }.tabBar(this.tabItem('纪念', 3))
    }
    .barHeight(56 + this.bottomInset)
    .barMode(BarMode.Fixed)
    .barBackgroundColor(Color.White)
    .scrollable(false)
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
    .onChange((index: number) => {
      this.currentTab = index;
    })
  }
}
