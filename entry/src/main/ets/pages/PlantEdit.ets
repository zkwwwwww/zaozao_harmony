import { common } from '@kit.AbilityKit';
import { Environment, Plant, Theme } from '../model/types';
import { PLANTING_OPTIONS, PURCHASE_OPTIONS, STATUS_OPTIONS } from '../common/constants';
import { errorText, fmtParts, positiveInt, sanitizeDecimal, sanitizeInt, singleIndex, today } from '../common/format';
import { seasonWaterText } from '../common/reminder';
import { takeRoute, navigationStack } from '../common/route';
import { findPlant } from '../common/viewmodel';
import { pickPhotos, takePhoto } from '../store/Media';
import { PlantRepository } from '../store/PlantRepository';
import { FieldLabel, PageHeader, PrimaryButton, SelectRow } from '../components/Chrome';

@Component
export struct PlantEdit {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('bottomInset') bottomInset: number = 0;
  @State pageTitle: string = '添加植物';
  @State plantId: string = '';
  @State name: string = '';
  @State variety: string = '';
  @State status: string = '健康';
  @State price: string = '';
  @State purchaseWay: string = '线上网店';
  @State planting: string = '土培';
  @State environmentId: string = '';
  @State envName: string = '';
  @State location: string = '';
  @State companionStart: string = '';
  @State purchaseDate: string = '';
  @State description: string = '';
  @State waterInterval: string = '';
  @State fertInterval: string = '';
  @State repotInterval: string = '';
  @State photos: string[] = [];
  @State envs: Environment[] = [];
  @State saving: boolean = false;
  @State season: string = '';

  aboutToAppear(): void {
    const route = takeRoute();
    this.season = seasonWaterText();
    this.envs = PlantRepository.current().envs;
    const todayText = today();
    this.purchaseDate = todayText;
    this.companionStart = todayText;
    if (route.plantId.length > 0) {
      const plant = findPlant(PlantRepository.current().plants, route.plantId);
      if (plant !== null) {
        this.pageTitle = '编辑植物';
        this.plantId = plant.id;
        this.name = plant.name;
        this.variety = plant.variety;
        this.status = plant.status.length > 0 ? plant.status : '健康';
        this.price = plant.price;
        this.purchaseWay = plant.purchaseWay.length > 0 ? plant.purchaseWay : '线上网店';
        this.planting = plant.planting.length > 0 ? plant.planting : '土培';
        this.environmentId = plant.environmentId;
        this.location = plant.location;
        this.companionStart = plant.companionStart;
        this.purchaseDate = plant.purchaseDate;
        this.description = plant.description;
        this.waterInterval = plant.customWaterInterval > 0 ? String(plant.customWaterInterval) : '';
        this.fertInterval = plant.customFertInterval > 0 ? String(plant.customFertInterval) : '';
        this.repotInterval = plant.customRepotInterval > 0 ? String(plant.customRepotInterval) : '';
        this.photos = plant.photos.slice();
      }
    }
    this.syncEnvName();
    if (this.environmentId.length === 0 && this.envs.length > 0 && this.plantId.length === 0) {
      this.environmentId = this.envs[0].id;
      this.envName = this.envs[0].name;
    }
  }

  private syncEnvName(): void {
    this.envName = '';
    for (let i = 0; i < this.envs.length; i++) {
      if (this.envs[i].id === this.environmentId) this.envName = this.envs[i].name;
    }
  }

  private toast(text: string): void {
    this.getUIContext().getPromptAction().showToast({ message: text });
  }

  private context(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private indexOf(options: string[], value: string): number {
    const index = options.indexOf(value);
    return index >= 0 ? index : 0;
  }

  private pickText(title: string, options: string[], current: string, apply: (value: string) => void): void {
    TextPickerDialog.show({
      range: options,
      selected: this.indexOf(options, current),
      onAccept: (result: TextPickerResult) => {
        const picked = singleIndex(result.index);
        if (picked >= 0 && picked < options.length) apply(options[picked]);
      }
    });
  }

  private pickDate(current: string, apply: (value: string) => void): void {
    const selected = current.length > 0 ? new Date(current + 'T12:00:00') : new Date();
    DatePickerDialog.show({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: selected,
      onDateAccept: (value: DatePickerResult) => {
        apply(fmtParts(value.year, value.month + 1, value.day));
      }
    });
  }

  private addPhoto(): void {
    if (this.photos.length >= 9 || this.saving) return;
    this.getUIContext().getPromptAction().showActionSheet({
      title: '添加照片',
      sheets: [{ title: '从相册选择' }, { title: '拍照' }],
      onAccept: (index: number) => {
        if (index === 0) this.fromAlbum();
        else this.fromCamera();
      }
    });
  }

  private fromAlbum(): void {
    this.saving = true;
    pickPhotos(9 - this.photos.length).then((paths: string[]) => {
      this.saving = false;
      if (paths.length === 0) return;
      const next: string[] = [];
      for (let i = 0; i < this.photos.length; i++) next.push(this.photos[i]);
      for (let i = 0; i < paths.length; i++) next.push(paths[i]);
      this.photos = next;
    }).catch((err: Object) => {
      this.saving = false;
      this.toast(errorText(err));
    });
  }

  private fromCamera(): void {
    this.saving = true;
    takePhoto(this.context()).then((path: string) => {
      this.saving = false;
      if (path.length === 0) return;
      const next: string[] = [];
      for (let i = 0; i < this.photos.length; i++) next.push(this.photos[i]);
      next.push(path);
      this.photos = next;
    }).catch((err: Object) => {
      this.saving = false;
      this.toast(errorText(err));
    });
  }

  private removePhoto(path: string): void {
    const next: string[] = [];
    for (let i = 0; i < this.photos.length; i++) {
      if (this.photos[i] !== path) next.push(this.photos[i]);
    }
    this.photos = next;
  }

  private save(): void {
    if (this.saving) return;
    if (this.name.trim().length === 0) {
      this.toast('请填写植物名称');
      return;
    }
    const plant = new Plant();
    plant.id = this.plantId;
    plant.name = this.name.trim();
    plant.variety = this.variety.trim();
    plant.status = this.status;
    plant.price = sanitizeDecimal(this.price);
    plant.purchaseWay = this.purchaseWay;
    plant.planting = this.planting;
    plant.environmentId = this.environmentId;
    plant.location = this.location.trim();
    plant.companionStart = this.companionStart;
    plant.purchaseDate = this.purchaseDate;
    plant.description = this.description.trim();
    plant.customWaterInterval = positiveInt(this.waterInterval);
    plant.customFertInterval = positiveInt(this.fertInterval);
    plant.customRepotInterval = positiveInt(this.repotInterval);
    plant.photos = this.photos;
    this.saving = true;
    PlantRepository.savePlant(plant).then(() => {
      this.saving = false;
      this.toast('已保存');
      this.pathStack.pop();
    }).catch((err: Object) => {
      this.saving = false;
      this.toast(errorText(err));
    });
  }

  build() {
    Column() {
      PageHeader({ title: this.pageTitle, showBack: true })
      Scroll() {
        Column() {
          Text(this.season + '。浇水间隔留空就按季节，施肥留空是 30 天，换盆留空是 365 天。')
            .fontSize(13)
            .fontColor(Theme.sub)
            .lineHeight(20)
            .width('100%')

          FieldLabel({ text: '名称' })
          TextInput({ text: this.name, placeholder: '给这株植物起个名字' })
            .height(48)
            .maxLength(40)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.name = value; })

          FieldLabel({ text: '品种' })
          TextInput({ text: this.variety, placeholder: '例如：绿萝、龟背竹' })
            .height(48)
            .maxLength(40)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.variety = value; })

          FieldLabel({ text: '状态' })
          SelectRow({
            value: this.status,
            onPick: () => {
              this.pickText('状态', STATUS_OPTIONS, this.status, (value: string) => { this.status = value; });
            }
          })

          FieldLabel({ text: '价格' })
          TextInput({ text: this.price, placeholder: '可以不填' })
            .type(InputType.Number)
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.price = sanitizeDecimal(value); })

          FieldLabel({ text: '购买途径' })
          SelectRow({
            value: this.purchaseWay,
            onPick: () => {
              this.pickText('购买途径', PURCHASE_OPTIONS, this.purchaseWay, (value: string) => { this.purchaseWay = value; });
            }
          })

          FieldLabel({ text: '种植形式' })
          SelectRow({
            value: this.planting,
            onPick: () => {
              this.pickText('种植形式', PLANTING_OPTIONS, this.planting, (value: string) => { this.planting = value; });
            }
          })

          FieldLabel({ text: '生长环境' })
          SelectRow({
            value: this.envName,
            placeholder: '未分类',
            onPick: () => {
              if (this.envs.length === 0) {
                this.toast('请先在环境页新建一个环境');
                return;
              }
              const names: string[] = [];
              for (let i = 0; i < this.envs.length; i++) names.push(this.envs[i].name);
              this.pickText('生长环境', names, this.envName, (value: string) => {
                for (let i = 0; i < this.envs.length; i++) {
                  if (this.envs[i].name === value) {
                    this.environmentId = this.envs[i].id;
                    this.envName = this.envs[i].name;
                  }
                }
              });
            }
          })

          FieldLabel({ text: '具体位置' })
          TextInput({ text: this.location, placeholder: '例如：书桌左侧' })
            .height(48)
            .maxLength(40)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.location = value; })

          FieldLabel({ text: '购买日期' })
          SelectRow({
            value: this.purchaseDate,
            placeholder: '选择日期',
            onPick: () => {
              this.pickDate(this.purchaseDate, (value: string) => { this.purchaseDate = value; });
            }
          })

          FieldLabel({ text: '陪伴起始' })
          SelectRow({
            value: this.companionStart,
            placeholder: '默认跟购买日期相同',
            onPick: () => {
              this.pickDate(this.companionStart, (value: string) => { this.companionStart = value; });
            }
          })

          FieldLabel({ text: '浇水间隔（天，可留空）' })
          TextInput({ text: this.waterInterval, placeholder: '留空则按季节' })
            .type(InputType.Number)
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.waterInterval = sanitizeInt(value); })

          FieldLabel({ text: '施肥间隔（天，可留空）' })
          TextInput({ text: this.fertInterval, placeholder: '留空则 30 天' })
            .type(InputType.Number)
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.fertInterval = sanitizeInt(value); })

          FieldLabel({ text: '换盆间隔（天，可留空）' })
          TextInput({ text: this.repotInterval, placeholder: '留空则 365 天' })
            .type(InputType.Number)
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.repotInterval = sanitizeInt(value); })

          FieldLabel({ text: '备注' })
          TextArea({ text: this.description, placeholder: '来源、习性或其他想记住的事' })
            .height(100)
            .maxLength(500)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .onChange((value: string) => { this.description = value; })

          FieldLabel({ text: '照片 ' + this.photos.length + '/9' })
          Scroll() {
            Row({ space: 8 }) {
              ForEach(this.photos, (photo: string) => {
                Stack({ alignContent: Alignment.TopEnd }) {
                  Image(photo)
                    .width(76)
                    .height(76)
                    .borderRadius(12)
                    .objectFit(ImageFit.Cover)
                  Text('×')
                    .width(22)
                    .height(22)
                    .fontSize(14)
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Center)
                    .backgroundColor('#99000000')
                    .borderRadius(11)
                    .onClick(() => { this.removePhoto(photo); })
                }
              }, (photo: string) => photo)
              if (this.photos.length < 9) {
                Column() {
                  Text(this.saving ? '...' : '添加')
                    .fontSize(13)
                    .fontColor(Theme.primary)
                }
                .width(76)
                .height(76)
                .justifyContent(FlexAlign.Center)
                .borderRadius(12)
                .border({ width: 1, color: Theme.primary, style: BorderStyle.Dashed })
                .onClick(() => { this.addPhoto(); })
              }
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .align(Alignment.TopStart)

      Column() {
        PrimaryButton({
          text: '保存',
          loading: this.saving,
          onTap: () => { this.save(); }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: this.bottomInset + 12 })
      .backgroundColor(Theme.bg)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
