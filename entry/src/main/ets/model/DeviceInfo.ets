export enum SyncStatus {
  OFFLINE = 0,
  ONLINE = 1,
  SYNCING = 2,
  ERROR = 3
}

export class DeviceInfo {
  deviceId: string = ''
  deviceName: string = ''
  networkId: string = ''
  deviceType: string = ''
  syncStatus: SyncStatus = SyncStatus.OFFLINE
  lastSyncTime: number = 0

  static syncStatusToString(status: SyncStatus): string {
    switch (status) {
      case SyncStatus.OFFLINE:
        return 'Offline'
      case SyncStatus.ONLINE:
        return 'Online'
      case SyncStatus.SYNCING:
        return 'Syncing'
      case SyncStatus.ERROR:
        return 'Error'
      default:
        return 'Offline'
    }
  }

  isOnline(): boolean {
    return this.syncStatus === SyncStatus.ONLINE || this.syncStatus === SyncStatus.SYNCING
  }
}
