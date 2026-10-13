import { Theme } from '../model/types';
import { navigationStack } from '../common/route';

@Component
export struct PageHeader {
  title: string = '';
  showBack: boolean = false;
  action: string = '';
  onAction: () => void = (): void => {};
  @StorageLink('topInset') topInset: number = 36;
  @StorageLink('pathStack') pathStack: NavPathStack = navigationStack();

  build() {
    Row() {
      if (this.showBack) {
        Text('返回')
          .width(56)
          .fontSize(16)
          .fontColor(Color.White)
          .onClick(() => {
            this.pathStack.pop();
          })
      } else {
        Row().width(56)
      }
      Text(this.title)
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.action.length > 0) {
        Text(this.action)
          .width(64)
          .fontSize(15)
          .fontColor(Color.White)
          .textAlign(TextAlign.End)
          .onClick(() => {
            this.onAction();
          })
      } else {
        Row().width(64)
      }
    }
    .width('100%')
    .padding({
      top: this.topInset + 10,
      bottom: 12,
      left: 16,
      right: 16
    })
    .backgroundColor(Theme.primary)
    .alignItems(VerticalAlign.Center)
  }
}

@Component
export struct EmptyState {
  title: string = '';
  message: string = '';

  build() {
    Column() {
      Column() {
        Ellipse().width(34).height(14).fill('#B7E4C7')
        Capsule().width(6).height(26).fill(Theme.primary).margin({ top: -4 })
      }
      .width(76)
      .height(76)
      .borderRadius(38)
      .backgroundColor(Theme.sprout)
      .justifyContent(FlexAlign.Center)

      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.text)
        .margin({ top: 14 })
      Text(this.message)
        .fontSize(13)
        .fontColor(Theme.sub)
        .lineHeight(20)
        .textAlign(TextAlign.Center)
        .width('86%')
        .margin({ top: 6 })
    }
    .width('100%')
    .padding({ top: 28, bottom: 20 })
    .alignItems(HorizontalAlign.Center)
  }
}

@Component
export struct PlantCover {
  photo: string = '';

  build() {
    if (this.photo.length > 0) {
      Image(this.photo)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    } else {
      Column() {
        Ellipse().width(28).height(12).fill('#B7E4C7')
        Capsule().width(5).height(22).fill(Theme.primary).margin({ top: -2 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Theme.sprout)
    }
  }
}

@Component
export struct Tag {
  text: string = '';
  tone: string = 'green';

  build() {
    Text(this.text)
      .fontSize(12)
      .fontColor(this.foreground())
      .backgroundColor(this.background())
      .borderRadius(10)
      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
  }

  private foreground(): string {
    if (this.tone === 'red') return Theme.danger;
    if (this.tone === 'amber') return Theme.amber;
    if (this.tone === 'gray') return Theme.sub;
    if (this.tone === 'blue') return '#3D6B8C';
    return Theme.primaryDark;
  }

  private background(): string {
    if (this.tone === 'red') return '#F8E8E6';
    if (this.tone === 'amber') return '#F8EFD9';
    if (this.tone === 'gray') return '#EEF2EF';
    if (this.tone === 'blue') return '#E5F0F6';
    return Theme.sprout;
  }
}

@Component
export struct SectionTitle {
  title: string = '';
  extra: string = '';
  onExtra: () => void = (): void => {};

  build() {
    Row() {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.text)
        .layoutWeight(1)
      if (this.extra.length > 0) {
        Text(this.extra)
          .fontSize(13)
          .fontColor(Theme.primary)
          .onClick(() => {
            this.onExtra();
          })
      }
    }
    .width('100%')
    .margin({ top: 18, bottom: 10 })
  }
}

@Component
export struct SelectRow {
  value: string = '';
  placeholder: string = '请选择';
  onPick: () => void = (): void => {};

  build() {
    Row() {
      Text(this.value.length > 0 ? this.value : this.placeholder)
        .fontSize(16)
        .fontColor(this.value.length > 0 ? Theme.text : Theme.hint)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('选择')
        .fontSize(13)
        .fontColor(Theme.primary)
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .border({ width: 1, color: Theme.line })
    .onClick(() => {
      this.onPick();
    })
  }
}

@Component
export struct FieldLabel {
  text: string = '';

  build() {
    Text(this.text)
      .fontSize(13)
      .fontColor(Theme.sub)
      .margin({ top: 14, bottom: 6 })
  }
}

@Component
export struct PrimaryButton {
  text: string = '';
  danger: boolean = false;
  ghost: boolean = false;
  loading: boolean = false;
  onTap: () => void = (): void => {};

  build() {
    Button(this.loading ? '请稍候' : this.text)
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontColor(this.ghost ? Theme.primary : Color.White)
      .backgroundColor(this.ghost ? Color.White : (this.danger ? Theme.danger : Theme.primary))
      .borderRadius(24)
      .border(this.ghost ? { width: 1, color: Theme.line } : { width: 0, color: Color.Transparent })
      .enabled(!this.loading)
      .onClick(() => {
        this.onTap();
      })
  }
}
