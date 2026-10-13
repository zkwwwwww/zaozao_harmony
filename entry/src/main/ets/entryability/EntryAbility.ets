import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { display, window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { errorText } from '../common/format';
import { PlantRepository, setAppContext } from '../store/PlantRepository';

const DOMAIN = 0x0000;
const TAG = 'zaozao';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    setAppContext(this.context);
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, TAG, 'start %{public}s', want.bundleName ?? '');
    if (launchParam.launchReason !== undefined) {
      hilog.info(DOMAIN, TAG, 'launch reason ready');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const win = windowStage.getMainWindowSync();
    win.setWindowLayoutFullScreen(true).then(() => {
      this.applySystemBar(win);
      this.applyInsets(win);
    }).catch(() => {
      this.applyInsets(win);
    });
    win.on('avoidAreaChange', () => {
      this.applyInsets(win);
    });
    PlantRepository.init().then(() => {
      windowStage.loadContent('pages/Index');
    }).catch((err: Object) => {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', errorText(err));
      PlantRepository.lastError = errorText(err);
      windowStage.loadContent('pages/Index');
    });
  }

  private applySystemBar(win: window.Window): void {
    win.setWindowSystemBarProperties({
      statusBarContentColor: '#FFFFFF',
      navigationBarContentColor: '#1C2B24'
    });
  }

  private applyInsets(win: window.Window): void {
    const density = display.getDefaultDisplaySync().densityPixels;
    const scale = density > 0 ? density : 1;
    const top = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    let bottomPx = 0;
    try {
      const bottom = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      bottomPx = bottom.bottomRect.height;
    } catch (err) {
      bottomPx = 0;
    }
    const topVp = top.topRect.height / scale;
    const bottomVp = bottomPx / scale;
    AppStorage.setOrCreate('topInset', topVp > 0 ? topVp : 36);
    AppStorage.setOrCreate('bottomInset', bottomVp);
  }
}
