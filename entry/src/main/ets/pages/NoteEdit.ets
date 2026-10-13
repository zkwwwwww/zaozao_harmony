import { common } from '@kit.AbilityKit';
import { CareRecord, Theme } from '../model/types';
import { CARE_TYPES } from '../common/constants';
import { errorText, fmtParts, singleIndex, today } from '../common/format';
import { takeRoute, navigationStack } from '../common/route';
import { findPlant } from '../common/viewmodel';
import { pickPhotos, takePhoto } from '../store/Media';
import { PlantRepository } from '../store/PlantRepository';
import { FieldLabel, PageHeader, PrimaryButton, SelectRow } from '../components/Chrome';

@Component
export struct NoteEdit {
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();
  @StorageLink('bottomInset') bottomInset: number = 0;
  @State plantId: string = '';
  @State recordId: string = '';
  @State plantName: string = '';
  @State careType: string = '浇水';
  @State date: string = '';
  @State content: string = '';
  @State photo: string = '';
  @State missing: boolean = false;
  @State saving: boolean = false;

  aboutToAppear(): void {
    const route = takeRoute();
    this.plantId = route.plantId;
    this.recordId = route.recordId;
    this.date = today();
    if (route.careType.length > 0 && CARE_TYPES.indexOf(route.careType) >= 0) {
      this.careType = route.careType;
    }
    const plant = findPlant(PlantRepository.current().plants, route.plantId);
    if (plant === null) {
      this.missing = true;
      return;
    }
    this.plantName = plant.name;
    if (route.recordId.length > 0) {
      for (let i = 0; i < plant.records.length; i++) {
        const record = plant.records[i];
        if (record.id === route.recordId) {
          this.careType = record.type.length > 0 ? record.type : this.careType;
          this.date = record.date.length > 0 ? record.date : this.date;
          this.content = record.content;
          this.photo = record.photo;
          this.recordId = record.id;
        }
      }
    }
  }

  private toast(text: string): void {
    this.getUIContext().getPromptAction().showToast({ message: text });
  }

  private context(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  private pickType(): void {
    const index = CARE_TYPES.indexOf(this.careType);
    TextPickerDialog.show({
      range: CARE_TYPES,
      selected: index >= 0 ? index : 0,
      onAccept: (result: TextPickerResult) => {
        const picked = singleIndex(result.index);
        if (picked >= 0 && picked < CARE_TYPES.length) this.careType = CARE_TYPES[picked];
      }
    });
  }

  private pickDate(): void {
    const selected = this.date.length > 0 ? new Date(this.date + 'T12:00:00') : new Date();
    DatePickerDialog.show({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: selected,
      onDateAccept: (value: DatePickerResult) => {
        this.date = fmtParts(value.year, value.month + 1, value.day);
      }
    });
  }

  private addPhoto(): void {
    if (this.saving) return;
    this.getUIContext().getPromptAction().showActionSheet({
      title: '记录照片',
      sheets: [{ title: '从相册选择' }, { title: '拍照' }],
      onAccept: (index: number) => {
        this.saving = true;
        const done = (path: string) => {
          this.saving = false;
          if (path.length > 0) this.photo = path;
        };
        const fail = (err: Object) => {
          this.saving = false;
          this.toast(errorText(err));
        };
        if (index === 0) {
          pickPhotos(1).then((paths: string[]) => done(paths.length > 0 ? paths[0] : '')).catch(fail);
        } else {
          takePhoto(this.context()).then(done).catch(fail);
        }
      }
    });
  }

  private save(): void {
    if (this.saving || this.missing) return;
    if (this.date.length === 0) {
      this.toast('请选择日期');
      return;
    }
    const record = new CareRecord();
    record.id = this.recordId;
    record.plantId = this.plantId;
    record.type = this.careType;
    record.date = this.date;
    record.content = this.content.trim();
    record.photo = this.photo;
    this.saving = true;
    PlantRepository.saveRecord(record).then(() => {
      this.saving = false;
      this.toast('已记下');
      this.pathStack.pop();
    }).catch((err: Object) => {
      this.saving = false;
      this.toast(errorText(err));
    });
  }

  build() {
    Column() {
      PageHeader({ title: this.recordId.length > 0 ? '编辑记录' : '养护记录', showBack: true })
      if (this.missing) {
        Text('植物不存在或已被删除')
          .fontSize(15)
          .fontColor(Theme.sub)
          .margin(24)
      } else {
        Scroll() {
          Column() {
            Text(this.plantName)
              .fontSize(14)
              .fontColor(Theme.sub)
              .width('100%')
            FieldLabel({ text: '类型' })
            SelectRow({ value: this.careType, onPick: () => { this.pickType(); } })
            FieldLabel({ text: '日期' })
            SelectRow({ value: this.date, onPick: () => { this.pickDate(); } })
            FieldLabel({ text: '内容' })
            TextArea({ text: this.content, placeholder: '浇了多少、施了什么肥，或者测量结果' })
              .height(120)
              .maxLength(500)
              .backgroundColor(Color.White)
              .borderRadius(12)
              .onChange((value: string) => { this.content = value; })
            FieldLabel({ text: '照片' })
            if (this.photo.length > 0) {
              Stack({ alignContent: Alignment.TopEnd }) {
                Image(this.photo)
                  .width(120)
                  .height(120)
                  .borderRadius(12)
                  .objectFit(ImageFit.Cover)
                Text('移除')
                  .fontSize(12)
                  .fontColor(Color.White)
                  .backgroundColor('#99000000')
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .onClick(() => { this.photo = ''; })
              }
            } else {
              Column() {
                Text(this.saving ? '请稍候' : '添加照片')
                  .fontSize(14)
                  .fontColor(Theme.primary)
              }
              .width(120)
              .height(88)
              .justifyContent(FlexAlign.Center)
              .borderRadius(12)
              .border({ width: 1, color: Theme.primary, style: BorderStyle.Dashed })
              .onClick(() => { this.addPhoto(); })
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
          PrimaryButton({ text: '保存记录', loading: this.saving, onTap: () => { this.save(); } })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: this.bottomInset + 12 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.bg)
  }
}
