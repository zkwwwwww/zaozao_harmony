import { Environment, LuxRow, Theme } from '../model/types';
import { luxRows } from '../common/constants';
import { errorText, sanitizeDecimal } from '../common/format';
import { takeRoute, navigationStack } from '../common/route';
import { findEnv } from '../common/viewmodel';
import { PlantRepository } from '../store/PlantRepository';
import { FieldLabel, PageHeader, PrimaryButton } from '../components/Chrome';

@Component
export struct EnvironmentEdit {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('bottomInset') bottomInset: number = 0;
  @State envId: string = '';
  @State name: string = '';
  @State lightIntensity: string = '';
  @State lightHours: string = '';
  @State sortOrder: number = 0;
  @State saving: boolean = false;
  @State rows: LuxRow[] = [];

  aboutToAppear(): void {
    this.rows = luxRows();
    const route = takeRoute();
    if (route.envId.length === 0) return;
    const env = findEnv(PlantRepository.current().envs, route.envId);
    if (env === null) return;
    this.envId = env.id;
    this.name = env.name;
    this.lightIntensity = env.lightIntensity;
    this.lightHours = env.lightHours;
    this.sortOrder = env.sortOrder;
  }

  private toast(text: string): void {
    this.getUIContext().getPromptAction().showToast({ message: text });
  }

  private save(): void {
    if (this.saving) return;
    const env = new Environment();
    env.id = this.envId;
    env.name = this.name;
    env.lightIntensity = sanitizeDecimal(this.lightIntensity);
    env.lightHours = sanitizeDecimal(this.lightHours);
    env.sortOrder = this.sortOrder;
    this.saving = true;
    PlantRepository.saveEnv(env).then(() => {
      this.saving = false;
      this.toast('已保存');
      this.pathStack.pop();
    }).catch((err: Object) => {
      this.saving = false;
      this.toast(errorText(err));
    });
  }

  private remove(): void {
    if (this.envId.length === 0) return;
    AlertDialog.show({
      title: '删除环境',
      message: '删除「' + (this.name.length > 0 ? this.name : '该环境') + '」后，使用它的植物会变为未分类。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        fontColor: Theme.danger,
        action: () => {
          PlantRepository.deleteEnv(this.envId).then(() => {
            this.toast('已删除');
            this.pathStack.pop();
          }).catch((err: Object) => {
            this.toast(errorText(err));
          });
        }
      }
    });
  }

  build() {
    Column() {
      PageHeader({ title: this.envId.length > 0 ? '编辑环境' : '新建环境', showBack: true })
      Scroll() {
        Column() {
          FieldLabel({ text: '名称' })
          TextInput({ text: this.name, placeholder: '例如：阳台直射、半阴散射光' })
            .height(48)
            .maxLength(30)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.name = value; })

          FieldLabel({ text: '光照强度（lux）' })
          TextInput({ text: this.lightIntensity, placeholder: '例如：5000' })
            .type(InputType.Number)
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.lightIntensity = sanitizeDecimal(value); })

          FieldLabel({ text: '每日光照时长（小时）' })
          TextInput({ text: this.lightHours, placeholder: '例如：8' })
            .type(InputType.Number)
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.lightHours = sanitizeDecimal(value); })

          Text('光照强度参考（lux）')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.text)
            .margin({ top: 22, bottom: 8 })
            .width('100%')
          Column() {
            ForEach(this.rows, (row: LuxRow) => {
              Row() {
                Text(row.label)
                  .fontSize(14)
                  .fontColor(Theme.text)
                  .layoutWeight(1)
                Text(row.value)
                  .fontSize(13)
                  .fontColor(Theme.sub)
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            }, (row: LuxRow) => row.label)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .backgroundColor(Color.White)
          .borderRadius(16)

          if (this.envId.length > 0) {
            Button('删除这个环境')
              .width('100%')
              .height(48)
              .margin({ top: 24 })
              .fontSize(16)
              .fontColor(Theme.danger)
              .backgroundColor(Color.White)
              .borderRadius(24)
              .onClick(() => { this.remove(); })
          }
        }
        .width('100%')
        .padding(16)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)

      Column() {
        PrimaryButton({ text: '保存', loading: this.saving, onTap: () => { this.save(); } })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: this.bottomInset + 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
