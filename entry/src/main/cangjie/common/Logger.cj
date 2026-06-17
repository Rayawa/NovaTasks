import { hilog } from '@kit.PerformanceAnalysisKit'
import { Constants } from '../common/Constants'

export class Logger {
  static info(tag: string, format: string, ...args: string[]): void {
    hilog.info(Constants.APP_DOMAIN, tag, format, ...args)
  }

  static warn(tag: string, format: string, ...args: string[]): void {
    hilog.warn(Constants.APP_DOMAIN, tag, format, ...args)
  }

  static error(tag: string, format: string, ...args: string[]): void {
    hilog.error(Constants.APP_DOMAIN, tag, format, ...args)
  }

  static debug(tag: string, format: string, ...args: string[]): void {
    hilog.debug(Constants.APP_DOMAIN, tag, format, ...args)
  }
}
