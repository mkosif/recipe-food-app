import { hilog } from '@kit.PerformanceAnalysisKit';

class Logger {
  private domain: number;
  private prefix: string;
  private format: string = '%{public}s';

  constructor(prefix: string = 'MyApp', domain: number = 0xFF00) {
    this.prefix = prefix;
    this.domain = domain;
  }

  debug(...args: string[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args.join(' '));
  }

  info(...args: string[]): void {
    hilog.info(this.domain, this.prefix, this.format, args.join(' '));
  }

  warn(...args: string[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args.join(' '));
  }

  error(...args: string[]): void {
    hilog.error(this.domain, this.prefix, this.format, args.join(' '));
  }
}

export default new Logger('Rdb', 0xFF00)
