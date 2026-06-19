import { DeviceInfo, SyncStatus } from '../model/DeviceInfo'
import { DistributedManager } from '../manager/DistributedManager'
import { TaskRepository } from '../manager/TaskRepository'
import { APP_NAME } from '../common/Constants'

@Component
export struct SettingsPage {
  @Consume('navStack') navStack: NavPathStack
  @State apiBaseUrl: string = 'https://api.novatask.example.com/v1'
  @State isDiscovering: boolean = false
  @State discoveredDevices: DeviceInfo[] = []
  @State isSyncActive: boolean = false
  @State syncSessionId: string = ''

  aboutToAppear(): void {
    this.discoveredDevices = DistributedManager.getInstance().getDiscoveredDevices()
  }

  build() {
    Column() {
      this.settingsHeader()
      Scroll() {
        Column({ space: 16 }) {
          this.apiConfigSection()
          this.distributedSection()
          this.dataSection()
          this.aboutSection()
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  settingsHeader() {
    Row() {
      Text('\u2190')
        .fontSize(24)
        .fontColor($r('app.color.icon_normal'))
        .onClick(() => {
          this.navStack.pop()
        })
      Text('Settings')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_text'))
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  apiConfigSection() {
    Column({ space: 8 }) {
      Text('API Configuration')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_text'))

      Row() {
        Text('Base URL:')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width(80)
        TextInput({ text: this.apiBaseUrl })
          .fontSize(14)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.apiBaseUrl = value
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  distributedSection() {
    Column({ space: 8 }) {
      Text('Distributed Devices')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_text'))

      Row() {
        Button(this.isDiscovering ? 'Discovering...' : 'Discover Devices')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.distributed_primary'))
          .borderRadius(8)
          .enabled(!this.isDiscovering)
          .onClick(() => {
            this.isDiscovering = true
            DistributedManager.getInstance().discoverDevices()
            setTimeout(() => {
              this.discoveredDevices = DistributedManager.getInstance().getDiscoveredDevices()
              this.isDiscovering = false
            }, 5000)
          })

        Blank()

        Button(this.isSyncActive ? 'Sync Active' : 'Start Sync')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.isSyncActive ? $r('app.color.status_completed') : $r('app.color.brand_primary'))
          .borderRadius(8)
          .enabled(!this.isSyncActive)
          .onClick(() => {
            this.startDistributedSync()
          })
      }
      .width('100%')

      if (this.discoveredDevices.length === 0) {
        Text('No devices found')
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      } else {
        ForEach(this.discoveredDevices, (device: DeviceInfo) => {
          Row() {
            Column() {
              Text(device.deviceName)
                .fontSize(14)
                .fontColor($r('app.color.title_text'))
              Text(device.deviceType)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Blank()

            Row() {
              Circle()
                .width(8)
                .height(8)
                .fill(device.isOnline() ? $r('app.color.status_completed') : $r('app.color.text_hint'))
              Text(DeviceInfo.syncStatusToString(device.syncStatus))
                .fontSize(12)
                .fontColor(device.isOnline() ? $r('app.color.status_completed') : $r('app.color.text_hint'))
                .margin({ left: 4 })
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius(8)
        }, (device: DeviceInfo) => device.deviceId)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  dataSection() {
    Column({ space: 8 }) {
      Text('Data Management')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_text'))

      Row() {
        Button('Clear All Data')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.status_failed'))
          .borderRadius(8)
          .onClick(() => {
            this.getUIContext().showAlertDialog({
              title: 'Confirm Clear Data',
              message: 'This will delete all tasks. Are you sure?',
              primaryButton: {
                value: 'Clear',
                action: () => {
                  this.getUIContext().getPromptAction().showToast({ message: 'Data cleared' })
                }
              },
              secondaryButton: {
                value: 'Cancel',
                action: () => {}
              }
            })
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  aboutSection() {
    Column({ space: 4 }) {
      Text('About')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.title_text'))
      Text(APP_NAME + ' v1.0.0')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
      Text('Built with HarmonyOS API 26')
        .fontSize(12)
        .fontColor($r('app.color.text_hint'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  private async startDistributedSync(): Promise<void> {
    this.isSyncActive = true
    let dm = DistributedManager.getInstance()
    let repo = TaskRepository.getInstance()
    let tasks = repo.getAllTasks()
    await dm.createDistributedObject(tasks)
    await dm.joinDefaultSession()
    dm.onDataChange((sessionId: string, fields: string[]) => {
      this.syncSessionId = sessionId
    })
  }
}
