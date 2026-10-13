import { common } from '@kit.AbilityKit';
import { Plant, Theme } from '../model/types';
import { APP_VERSION } from '../common/constants';
import { errorText } from '../common/format';
import { openPage, navigationStack } from '../common/route';
import { memorialPlants } from '../common/viewmodel';
import { PlantRepository } from '../store/PlantRepository';
import { exportBackup, importBackup } from '../store/Backup';
import { EmptyState, PageHeader, PlantCover, PrimaryButton, Tag } from '../components/Chrome';

@Component
export struct MemorialTab {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('bottomInset') bottomInset: number = 0;
  @StorageLink('revision') @Watch('onRevision') revision: number = 0;
  @State list: Plant[] = [];
  @State busy: boolean = false;
  @State message: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  onRevision(): void {
    this.refresh();
  }

  private refresh(): void {
    this.list = memorialPlants(PlantRepository.current());
  }

  private toast(text: string): void {
    this.getUIContext().getPromptAction().showToast({ message: text });
  }

  private context(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private exportFile(): void {
    if (this.busy) return;
    this.busy = true;
    this.message = '';
    exportBackup(this.context()).then((text: string) => {
      this.busy = false;
      if (text.length > 0) this.toast(text);
    }).catch((err: Object) => {
      this.busy = false;
      this.message = errorText(err);
    });
  }

  private importFile(): void {
    if (this.busy) return;
    AlertDialog.show({
      title: '合并备份',
      message: '会按编号合并到这台设备。相同编号会被备份覆盖，其他本机记录会保留。备份里的照片也会一起恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '选择文件',
        fontColor: Theme.primary,
        action: () => {
          this.busy = true;
          importBackup(this.context()).then((text: string) => {
            this.busy = false;
            if (text.length > 0) this.toast(text);
          }).catch((err: Object) => {
            this.busy = false;
            this.message = errorText(err);
          });
        }
      }
    });
  }

  private restore(plant: Plant): void {
    AlertDialog.show({
      title: '恢复植物',
      message: '「' + plant.name + '」会回到主页，纪念碑会去掉。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '恢复',
        fontColor: Theme.primary,
        action: () => {
          PlantRepository.restorePlant(plant.id).then(() => {
            this.toast('已恢复');
          }).catch((err: Object) => {
            this.toast(errorText(err));
          });
        }
      }
    });
  }

  build() {
    Column() {
      PageHeader({ title: '纪念碑' })
      Scroll() {
        Column() {
          Text('送人或离开的植物会留在这里，记得陪伴了多久。需要的话可以随时恢复。')
            .fontSize(13)
            .fontColor(Theme.sub)
            .lineHeight(20)
            .width('100%')

          if (this.list.length === 0) {
            EmptyState({ title: '纪念碑还是空的', message: '在植物详情里可以选择送人或去世，为主页腾出位置，记录仍然留着。' })
          }

          ForEach(this.list, (plant: Plant) => {
            Column() {
              Row() {
                Stack() {
                  PlantCover({ photo: plant.photos.length > 0 ? plant.photos[0] : '' })
                }
                .width(72)
                .height(72)
                .borderRadius(12)
                .clip(true)

                Column() {
                  Text(plant.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.text)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Row() {
                    Tag({
                      text: plant.memorialType.length > 0 ? plant.memorialType : '纪念',
                      tone: plant.memorialType === '送人' ? 'blue' : 'gray'
                    })
                    Text(plant.memorialDate)
                      .fontSize(12)
                      .fontColor(Theme.sub)
                      .margin({ left: 8 })
                  }
                  .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 12 })
              }
              .width('100%')

              if (plant.companionSnapshot.length > 0) {
                Text('陪伴 ' + plant.companionSnapshot)
                  .fontSize(13)
                  .fontColor(Theme.sub)
                  .margin({ top: 10 })
                  .width('100%')
              }
              if (plant.memorialNote.length > 0) {
                Text(plant.memorialNote)
                  .fontSize(14)
                  .fontColor(Theme.text)
                  .lineHeight(20)
                  .margin({ top: 6 })
                  .width('100%')
              }

              Row({ space: 10 }) {
                Button('查看')
                  .height(36)
                  .fontSize(14)
                  .fontColor(Theme.primaryDark)
                  .backgroundColor(Theme.bg)
                  .borderRadius(18)
                  .onClick(() => {
                    openPage(this.pathStack, 'PlantDetail', plant.id, '', '', '');
                  })
                Button('恢复到主页')
                  .height(36)
                  .fontSize(14)
                  .fontColor(Theme.primary)
                  .backgroundColor(Theme.sprout)
                  .borderRadius(18)
                  .onClick(() => {
                    this.restore(plant);
                  })
              }
              .margin({ top: 12 })
            }
            .width('100%')
            .padding(14)
            .margin({ top: 12 })
            .backgroundColor(Color.White)
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
          }, (plant: Plant) => plant.id)

          Text('本机数据')
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.text)
            .margin({ top: 28, bottom: 8 })
            .width('100%')
          Text('植物、环境和照片都只在这台设备上。卸载或清除数据前，先导出一份备份。')
            .fontSize(13)
            .fontColor(Theme.sub)
            .lineHeight(20)
            .width('100%')

          Column({ space: 10 }) {
            PrimaryButton({
              text: '导出备份',
              loading: this.busy,
              onTap: () => {
                this.exportFile();
              }
            })
            PrimaryButton({
              text: '从备份合并',
              ghost: true,
              loading: this.busy,
              onTap: () => {
                this.importFile();
              }
            })
            PrimaryButton({
              text: '隐私说明',
              ghost: true,
              onTap: () => {
                openPage(this.pathStack, 'PrivacyPage', '', '', '', '');
              }
            })
          }
          .margin({ top: 14 })
          .width('100%')

          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(13)
              .fontColor(Theme.danger)
              .margin({ top: 10 })
              .width('100%')
          }

          Text('版本 ' + APP_VERSION + ' · 无账号，数据不上传')
            .fontSize(12)
            .fontColor(Theme.hint)
            .margin({ top: 16, bottom: this.bottomInset })
            .width('100%')
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
