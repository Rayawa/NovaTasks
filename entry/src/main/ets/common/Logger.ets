import { hilog } from '@kit.PerformanceAnalysisKit'
import { APP_DOMAIN } from '../common/Constants'

export class Logger {
  static info(tag: string, format: string, ...args: string[]): void {
    hilog.info(APP_DOMAIN, tag, format, ...args)
  }

  static warn(tag: string, format: string, ...args: string[]): void {
    hilog.warn(APP_DOMAIN, tag, format, ...args)
  }

  static error(tag: string, format: string, ...args: string[]): void {
    hilog.error(APP_DOMAIN, tag, format, ...args)
  }

  static debug(tag: string, format: string, ...args: string[]): void {
    hilog.debug(APP_DOMAIN, tag, format, ...args)
  }
}
