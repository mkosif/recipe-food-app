import Recipe from '../../model/Recipe';
import TimerService from '../../service/TimerService';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

const TIMER_KEY_PREFIX = 'cookmode_step_';

@Component
export struct CookModePageDestination {
  @Prop recipe: Recipe;
  @State private stepIndex: number = 0;
  @State private remainingSec: number = 0;
  @State private timerLabel: string = '';
  private tickHandle: number = -1;
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.enableKeepScreenOn(true);
  }

  aboutToDisappear(): void {
    this.enableKeepScreenOn(false);
    this.stopTick();
    TimerService.getInstance().cancelAll();
  }

  private async enableKeepScreenOn(enable: boolean): Promise<void> {
    try {
      if (!this.context) {
        return;
      }
      const win = await window.getLastWindow(this.context);
      await win.setWindowKeepScreenOn(enable);
    } catch (err) {
      console.error('[CookMode] keepScreenOn failed:', JSON.stringify(err));
    }
  }

  private get timerKey(): string {
    return `${TIMER_KEY_PREFIX}${this.recipe.id}_${this.stepIndex}`;
  }

  private nextStep(): void {
    if (this.stepIndex < this.recipe.steps.length - 1) {
      this.stepIndex += 1;
      TimerService.getInstance().vibrateTick();
    }
  }

  private prevStep(): void {
    if (this.stepIndex > 0) {
      this.stepIndex -= 1;
      TimerService.getInstance().vibrateTick();
    }
  }

  private async startQuickTimer(minutes: number): Promise<void> {
    const svc = TimerService.getInstance();
    const label = `${this.recipe.name} · ${this.stepIndex + 1}/${this.recipe.steps.length}`;
    const ok = await svc.startTimer(this.timerKey, label, minutes * 60);
    if (ok) {
      this.timerLabel = `${minutes} dk`;
      this.remainingSec = minutes * 60;
      this.startTick();
      svc.vibrateSuccess();
    }
  }

  private async cancelCurrentTimer(): Promise<void> {
    await TimerService.getInstance().cancelTimer(this.timerKey);
    this.stopTick();
    this.remainingSec = 0;
    this.timerLabel = '';
  }

  private startTick(): void {
    this.stopTick();
    this.tickHandle = setInterval(() => {
      const rem = TimerService.getInstance().remainingSec(this.timerKey);
      this.remainingSec = rem;
      if (rem <= 0) {
        this.stopTick();
      }
    }, 1000);
  }

  private stopTick(): void {
    if (this.tickHandle !== -1) {
      clearInterval(this.tickHandle);
      this.tickHandle = -1;
    }
  }

  private formatTime(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('←')
            .fontSize(22)
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.navPathStack.pop())
          Blank().layoutWeight(1)
          Text(`${this.stepIndex + 1} / ${this.recipe.steps.length}`)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 6 })

        Scroll() {
          Text(this.recipe.steps[this.stepIndex] ?? '')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
            .padding({ left: 14, right: 14 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollable(ScrollDirection.Vertical)

        if (this.remainingSec > 0) {
          this.buildRunningTimer();
        } else {
          this.buildTimerPresets();
        }

        Row({ space: 10 }) {
          Button('‹')
            .fontSize(22)
            .fontColor($r('app.color.text_on_surface'))
            .backgroundColor($r('app.color.surface_primary'))
            .enabled(this.stepIndex > 0)
            .layoutWeight(1)
            .onClick(() => this.prevStep())
          Button('›')
            .fontSize(22)
            .fontColor($r('app.color.text_on_surface'))
            .backgroundColor($r('app.color.surface_primary'))
            .enabled(this.stepIndex < this.recipe.steps.length - 1)
            .layoutWeight(1)
            .onClick(() => this.nextStep())
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 10 })
      }
      .backgroundColor($r('app.color.background_primary'))
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
    })
  }

  @Builder
  private buildTimerPresets() {
    Row({ space: 6 }) {
      Button('1m')
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.text_secondary'), radius: 14 })
        .layoutWeight(1)
        .onClick(() => this.startQuickTimer(1))
      Button('5m')
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.text_secondary'), radius: 14 })
        .layoutWeight(1)
        .onClick(() => this.startQuickTimer(5))
      Button('10m')
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.text_secondary'), radius: 14 })
        .layoutWeight(1)
        .onClick(() => this.startQuickTimer(10))
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 8 })
  }

  @Builder
  private buildRunningTimer() {
    Row({ space: 8 }) {
      Text(this.formatTime(this.remainingSec))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Button('✕')
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .backgroundColor(Color.Transparent)
        .border({ width: 1, color: $r('app.color.text_secondary'), radius: 14 })
        .onClick(() => this.cancelCurrentTimer())
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 8 })
  }
}
