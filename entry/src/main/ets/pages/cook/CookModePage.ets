import Recipe from '../../model/Recipe';
import TimerService from '../../service/TimerService';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { extractTimerHint, StepTimerHint } from '../../util/StepTimer';

const TIMER_KEY_PREFIX = 'cookmode_step_';

// Crown rotation threshold (in degrees) for one discrete step change.
// Hardware crown clicks are typically ~10-15 degrees per detent on HarmonyOS wearables;
// 30 degrees gives a deliberate two-detent advance and avoids accidental skips.
const CROWN_STEP_THRESHOLD = 30;

// Minimal CrownEvent shape used as a structural fallback when reading the
// runtime payload, since the global `CrownEvent` type is consumed at the
// onDigitalCrown handler signature directly.
interface CrownEventLike {
  degree?: number;
  angularVelocity?: number;
}

@Component
export struct CookModePageDestination {
  @Prop recipe: Recipe = {
    id: '',
    name: '',
    imageSource: '',
    description: '',
    isFavorite: false,
    category: 'main',
    durationMin: 0,
    difficulty: 'easy',
    servings: 0,
    ingredients: [],
    steps: []
  };
  @State private stepIndex: number = 0;
  @State private remainingSec: number = 0;
  @State private stepHint: StepTimerHint | null = null;
  @State private timerComplete: boolean = false;
  @State private alarmActive: boolean = false;
  @State private alarmFlashOn: boolean = false;
  private tickHandle: number = -1;
  private alarmFlashHandle: number = -1;
  private alarmStopHandle: number = -1;
  private crownAccum: number = 0;
  private navPathStack: NavPathStack = new NavPathStack();
  @StorageLink('context') context: common.UIAbilityContext | null = null;

  aboutToAppear(): void {
    this.enableKeepScreenOn(true);
    this.refreshStepHint();
  }

  aboutToDisappear(): void {
    this.enableKeepScreenOn(false);
    this.stopTick();
    this.stopAlarmFeedback();
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
      const nextIndex = this.stepIndex + 1;
      this.stepIndex = nextIndex;
      this.refreshStepHint(nextIndex);
      this.timerComplete = false;
      this.stopAlarmFeedback();
      TimerService.getInstance().vibrateTick();
    }
  }

  private prevStep(): void {
    if (this.stepIndex > 0) {
      const nextIndex = this.stepIndex - 1;
      this.stepIndex = nextIndex;
      this.refreshStepHint(nextIndex);
      this.timerComplete = false;
      this.stopAlarmFeedback();
      TimerService.getInstance().vibrateTick();
    }
  }

  private refreshStepHint(index: number = this.stepIndex): void {
    const step = this.recipe.steps[index];
    this.stepHint = step ? extractTimerHint(step) : null;
  }

  private onCrown(degree: number): void {
    this.crownAccum += degree;
    if (this.crownAccum >= CROWN_STEP_THRESHOLD) {
      this.crownAccum = 0;
      this.nextStep();
    } else if (this.crownAccum <= -CROWN_STEP_THRESHOLD) {
      this.crownAccum = 0;
      this.prevStep();
    }
  }

  private async cancelCurrentTimer(): Promise<void> {
    await TimerService.getInstance().cancelTimer(this.timerKey);
    this.stopTick();
    this.remainingSec = 0;
    this.timerComplete = false;
    this.stopAlarmFeedback();
  }

  private startTick(): void {
    this.stopTick();
    this.tickHandle = setInterval(() => {
      const rem = TimerService.getInstance().remainingSec(this.timerKey);
      this.remainingSec = rem;
      if (rem <= 0) {
        this.stopTick();
        this.timerComplete = true;
        this.startAlarmFeedback();
        TimerService.getInstance().vibrateSuccess();
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

  private async startHintTimer(hint: StepTimerHint): Promise<void> {
    const svc = TimerService.getInstance();
    const label = `${this.recipe.name} · ${this.stepIndex + 1}/${this.recipe.steps.length}`;
    const ok = await svc.startTimer(this.timerKey, label, hint.durationSec);
    if (ok) {
      this.timerComplete = false;
      this.stopAlarmFeedback();
      this.remainingSec = hint.durationSec;
      this.startTick();
      svc.vibrateSuccess();
    }
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
          Text(`${this.stepIndex + 1}/${this.recipe.steps.length}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.accent_primary'))
        }
        .width('92%')
        .padding({ top: 8, bottom: 4 })

        if (this.remainingSec > 0) {
          this.buildTimerDock();
        } else if (this.timerComplete) {
          this.buildTimerDock();
        } else if (this.stepHint !== null) {
          this.buildTimerDock();
        }

        Scroll() {
          Text(this.recipe.steps[this.stepIndex] ?? '')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
            .lineHeight(22)
            .width('100%')
        }
        .layoutWeight(1)
        .width('86%')
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)

        Row({ space: 14 }) {
          Button('‹')
            .fontSize(20)
            .fontColor($r('app.color.text_on_surface'))
            .backgroundColor($r('app.color.surface_primary'))
            .border({ width: 1, color: $r('app.color.divider'), radius: 18 })
            .height(34)
            .width(74)
            .enabled(this.stepIndex > 0)
            .onClick(() => this.prevStep())
          Button('›')
            .fontSize(20)
            .fontColor($r('app.color.accent_on_primary'))
            .backgroundColor($r('app.color.accent_primary'))
            .height(34)
            .width(74)
            .enabled(this.stepIndex < this.recipe.steps.length - 1)
            .onClick(() => this.nextStep())
        }
        .justifyContent(FlexAlign.Center)
        .width('64%')
        .padding({ bottom: 8 })
      }
      .backgroundColor(this.alarmActive && this.alarmFlashOn
        ? Color.White
        : $r('app.color.background_primary'))
      .width('100%')
      .height('100%')
      .focusable(true)
      .defaultFocus(true)
      .onDigitalCrown((event: CrownEvent) => {
        const e = event as CrownEventLike;
        if (typeof e.degree === 'number') {
          this.onCrown(e.degree);
        }
      })
      .onClick(() => this.stopAlarmFeedback())
    }
    .hideTitleBar(true)
    .onReady((ctx: NavDestinationContext) => {
      this.navPathStack = ctx.pathStack;
    })
  }

  @Builder
  private buildTimerDock() {
    Row({ space: 6 }) {
      Text(this.timerComplete
        ? '00:00'
        : this.remainingSec > 0
          ? this.formatTime(this.remainingSec)
          : this.formatTime(this.stepHint!.durationSec))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Button(this.remainingSec > 0 ? 'Stop' : 'Start')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.remainingSec > 0 || this.timerComplete
          ? $r('app.color.text_primary')
          : $r('app.color.accent_on_primary'))
        .backgroundColor(this.remainingSec > 0 || this.timerComplete
          ? $r('app.color.surface_secondary')
          : $r('app.color.accent_primary'))
        .border({ width: 1, color: $r('app.color.divider'), radius: 16 })
        .height(32)
        .width(72)
        .onClick(() => {
          if (this.remainingSec > 0) {
            this.cancelCurrentTimer();
          } else if (this.timerComplete) {
            this.timerComplete = false;
            this.stopAlarmFeedback();
          } else if (this.stepHint !== null) {
            this.startHintTimer(this.stepHint);
          }
        })
    }
    .width('70%')
    .height(40)
    .padding({ left: 14, right: 4 })
    .backgroundColor($r('app.color.surface_primary'))
    .border({ width: 1, color: $r('app.color.divider'), radius: 20 })
    .margin({ bottom: 4 })
  }

  private startAlarmFeedback(): void {
    this.stopAlarmFeedback(false);
    this.alarmActive = true;
    this.alarmFlashOn = true;
    this.alarmFlashHandle = setInterval(() => {
      this.alarmFlashOn = !this.alarmFlashOn;
    }, 300);
    this.alarmStopHandle = setTimeout(() => {
      this.stopAlarmFeedback();
    }, 5000);
  }

  private stopAlarmFeedback(clearComplete: boolean = true): void {
    if (this.alarmFlashHandle !== -1) {
      clearInterval(this.alarmFlashHandle);
      this.alarmFlashHandle = -1;
    }
    if (this.alarmStopHandle !== -1) {
      clearTimeout(this.alarmStopHandle);
      this.alarmStopHandle = -1;
    }
    this.alarmActive = false;
    this.alarmFlashOn = false;
    if (clearComplete) {
      this.timerComplete = false;
    }
  }
}
