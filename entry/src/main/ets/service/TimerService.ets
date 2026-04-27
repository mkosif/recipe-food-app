import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { vibrator } from '@kit.SensorServiceKit';

export interface ActiveTimer {
  reminderId: number;
  label: string;
  durationSec: number;
  startedAtMs: number;
}

export default class TimerService {
  private static instance: TimerService | null = null;
  private active: Map<string, ActiveTimer> = new Map();

  private constructor() {}

  static getInstance(): TimerService {
    if (!TimerService.instance) {
      TimerService.instance = new TimerService();
    }
    return TimerService.instance;
  }

  async startTimer(key: string, label: string, durationSec: number): Promise<boolean> {
    await this.cancelTimer(key);

    const reminder: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: durationSec,
      title: label,
      content: label,
      ringDuration: 5,
      actionButton: [
        {
          title: 'OK',
          type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
        }
      ]
    };

    let reminderId = -1;
    try {
      reminderId = await reminderAgentManager.publishReminder(reminder);
      console.info(`[TimerService] publishReminder success: ${reminderId}`);
    } catch (err) {
      console.error('[TimerService] publishReminder failed:', JSON.stringify(err));
    }
    const timer: ActiveTimer = {
      reminderId,
      label,
      durationSec,
      startedAtMs: Date.now()
    };
    this.active.set(key, timer);
    return true;
  }

  async cancelTimer(key: string): Promise<void> {
    const timer = this.active.get(key);
    if (!timer) {
      return;
    }
    if (timer.reminderId >= 0) {
      try {
        await reminderAgentManager.cancelReminder(timer.reminderId);
      } catch (err) {
        console.error('[TimerService] cancelReminder failed:', JSON.stringify(err));
      }
    }
    this.active.delete(key);
  }

  async cancelAll(): Promise<void> {
    const keys = Array.from(this.active.keys());
    for (const key of keys) {
      await this.cancelTimer(key);
    }
  }

  getTimer(key: string): ActiveTimer | undefined {
    return this.active.get(key);
  }

  remainingSec(key: string): number {
    const timer = this.active.get(key);
    if (!timer) {
      return 0;
    }
    const elapsed = Math.floor((Date.now() - timer.startedAtMs) / 1000);
    const remaining = timer.durationSec - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  vibrateSuccess(): void {
    this.vibrateWithPreset('haptic.notice.success');
  }

  vibrateTick(): void {
    this.vibrateWithPreset('haptic.clock.timer');
  }

  private vibrateWithPreset(effectId: string): void {
    try {
      vibrator.startVibration(
        { type: 'preset', effectId, count: 1 },
        { usage: 'notification' },
        (err) => {
          if (err) {
            console.error('[TimerService] vibrate failed:', JSON.stringify(err));
          }
        }
      );
    } catch (err) {
      console.error('[TimerService] vibrate threw:', JSON.stringify(err));
    }
  }
}
