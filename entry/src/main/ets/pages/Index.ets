import { Theme } from '../model/types';
import { navigationStack } from '../common/route';
import { MainTabs } from './MainTabs';
import { PlantDetail } from './PlantDetail';
import { PlantEdit } from './PlantEdit';
import { NoteEdit } from './NoteEdit';
import { EnvironmentEdit } from './EnvironmentEdit';
import { PrivacyPage } from './PrivacyPage';

@Entry
@Component
struct Index {
  pathStack: NavPathStack = navigationStack();

  aboutToAppear(): void {
    AppStorage.setOrCreate('pathStack', navigationStack());
    if (AppStorage.get<number>('currentTab') === undefined) {
      AppStorage.setOrCreate('currentTab', 0);
    }
  }

  @Builder
  pageMap(name: string) {
    if (name === 'PlantDetail') {
      PlantDetail()
    } else if (name === 'PlantEdit') {
      PlantEdit()
    } else if (name === 'NoteEdit') {
      NoteEdit()
    } else if (name === 'EnvironmentEdit') {
      EnvironmentEdit()
    } else if (name === 'PrivacyPage') {
      PrivacyPage()
    }
  }

  build() {
    Navigation(this.pathStack) {
      MainTabs()
    }
    .hideTitleBar(true)
    .hideToolBar(true)
    .hideBackButton(true)
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
    .backgroundColor(Theme.bg)
    .width('100%')
    .height('100%')
  }
}
