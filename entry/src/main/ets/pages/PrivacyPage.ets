import { Theme } from '../model/types';
import { PageHeader } from '../components/Chrome';

@Component
export struct PrivacyPage {
  @StorageLink('bottomInset') bottomInset: number = 0;

  @Builder
  block(title: string, body: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.text)
        .width('100%')
      Text(body)
        .fontSize(14)
        .fontColor(Theme.sub)
        .lineHeight(22)
        .margin({ top: 6 })
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 18 })
  }

  build() {
    Column() {
      PageHeader({ title: '隐私说明', showBack: true })
      Scroll() {
        Column() {
          this.block('这个版本没有账号', '植早早当前不提供注册、登录或云同步。你不需要授权头像、昵称或手机号。')
          this.block('数据留在这台设备', '植物档案、生长环境、养护记录和照片保存在应用自己的本地数据库和文件目录里，不会上传到服务器。')
          this.block('照片怎么选', '添加照片时使用系统相册或系统相机。应用不申请读取整库照片的权限，也没有网络权限。')
          this.block('备份由你保管', '导出的 JSON 文件包含文字和照片，保存在你选择的位置。请自行保管这份文件；把它导入时，相同编号的记录会被覆盖。')
          this.block('删除', '可以在应用里删除植物、记录或环境。卸载应用或清除应用数据后，未导出的内容会一并消失。')
          Text('如果你之后需要换设备同步，需要先有自己的服务器。当前版本故意没有这一步。')
            .fontSize(13)
            .fontColor(Theme.hint)
            .lineHeight(20)
            .width('100%')
            .margin({ bottom: this.bottomInset + 24 })
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
