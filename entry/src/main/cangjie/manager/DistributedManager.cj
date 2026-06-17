import { distributedDataObject } from '@kit.ArkData'
import { distributedDeviceManager } from '@kit.DistributedServiceKit'
import { Context } from '@kit.AbilityKit'
import { Logger } from '../common/Logger'
import { DISTRIBUTED_SESSION_ID } from '../common/Constants'
import { TaskData } from '../model/TaskData'
import { DeviceInfo, SyncStatus } from '../model/DeviceInfo'

const TAG: string = 'DistributedManager'

interface DistributedSource {
  taskListJson: string
  lastSyncTime: number
}

interface DiscoverParam {
  discoverTargetType: number
}

export class DistributedManager {
  private static instance: DistributedManager | null = null
  private dataObject: distributedDataObject.DataObject | null = null
  private deviceManager: distributedDeviceManager.DeviceManager | null = null
  private sessionId: string = ''
  private discoveredDevices: DeviceInfo[] = []
  private context: Context | null = null

  static getInstance(): DistributedManager {
    if (DistributedManager.instance === null) {
      DistributedManager.instance = new DistributedManager()
    }
    return DistributedManager.instance
  }

  async init(context: Context): Promise<void> {
    this.context = context
    try {
      let dmInstance = distributedDeviceManager.createDeviceManager('top.rayawa.novatasks')
      this.deviceManager = dmInstance
      Logger.info(TAG, 'DeviceManager initialized')
    } catch (err) {
      Logger.error(TAG, 'Failed to init DeviceManager: ' + JSON.stringify(err))
    }
  }

  async createDistributedObject(tasks: TaskData[]): Promise<void> {
    if (this.context === null) {
      Logger.error(TAG, 'Context not initialized')
      return
    }
    try {
      let source: DistributedSource = {
        taskListJson: JSON.stringify(tasks.map((t: TaskData) => t.toJsonObject())),
        lastSyncTime: Date.now()
      }
      this.dataObject = distributedDataObject.create(this.context, source)
      Logger.info(TAG, 'Distributed data object created')
    } catch (err) {
      Logger.error(TAG, 'Failed to create distributed object: ' + JSON.stringify(err))
    }
  }

  async joinSession(sessionId: string): Promise<void> {
    if (this.dataObject === null) {
      Logger.error(TAG, 'Data object not created')
      return
    }
    try {
      this.sessionId = sessionId
      this.dataObject.setSessionId(sessionId)
      Logger.info(TAG, 'Joined session: ' + sessionId)
    } catch (err) {
      Logger.error(TAG, 'Failed to join session: ' + JSON.stringify(err))
    }
  }

  async joinDefaultSession(): Promise<void> {
    await this.joinSession(DISTRIBUTED_SESSION_ID)
  }

  leaveSession(): void {
    if (this.dataObject !== null) {
      this.dataObject.setSessionId('')
      this.sessionId = ''
      Logger.info(TAG, 'Left session')
    }
  }

  onDataChange(callback: (sessionId: string, fields: string[]) => void): void {
    if (this.dataObject !== null) {
      this.dataObject.on('change', callback)
      Logger.info(TAG, 'Data change listener registered')
    }
  }

  onStatusChange(callback: (sessionId: string, networkId: string, status: string) => void): void {
    if (this.dataObject !== null) {
      this.dataObject.on('status', callback)
      Logger.info(TAG, 'Status change listener registered')
    }
  }

  async updateDistributedData(tasks: TaskData[]): Promise<void> {
    if (this.dataObject !== null) {
      try {
        this.dataObject['taskListJson'] = JSON.stringify(tasks.map((t: TaskData) => t.toJsonObject()))
        this.dataObject['lastSyncTime'] = Date.now()
        Logger.info(TAG, 'Distributed data updated')
      } catch (err) {
        Logger.error(TAG, 'Failed to update distributed data: ' + JSON.stringify(err))
      }
    }
  }

  saveToLocal(deviceId: string): void {
    if (this.dataObject !== null) {
      this.dataObject.save(deviceId)
      Logger.info(TAG, 'Data saved to device: ' + deviceId)
    }
  }

  revokeSave(): void {
    if (this.dataObject !== null) {
      this.dataObject.revokeSave()
      Logger.info(TAG, 'Data save revoked')
    }
  }

  getDiscoveredDevices(): DeviceInfo[] {
    return this.discoveredDevices.slice()
  }

  discoverDevices(): void {
    if (this.deviceManager === null) {
      Logger.error(TAG, 'DeviceManager not initialized')
      return
    }
    try {
      this.deviceManager.on('deviceStateChange', (data: {
        action: distributedDeviceManager.DeviceStateChange;
        device: distributedDeviceManager.DeviceBasicInfo;
      }) => {
        let device = data.device
        let info = new DeviceInfo()
        info.deviceId = device.deviceId
        info.deviceName = device.deviceName
        info.networkId = device.networkId ?? ''
        info.deviceType = device.deviceType
        if (data.action === distributedDeviceManager.DeviceStateChange.AVAILABLE) {
          info.syncStatus = SyncStatus.ONLINE
        } else {
          info.syncStatus = SyncStatus.OFFLINE
        }
        info.lastSyncTime = Date.now()
        this.discoveredDevices = [info]
        Logger.info(TAG, 'Device state changed: ' + device.deviceName)
      })
      this.deviceManager.on('discoverSuccess', (data: {
        device: distributedDeviceManager.DeviceBasicInfo;
      }) => {
        let device = data.device
        let info = new DeviceInfo()
        info.deviceId = device.deviceId
        info.deviceName = device.deviceName
        info.networkId = device.networkId ?? ''
        info.deviceType = device.deviceType
        info.syncStatus = SyncStatus.ONLINE
        info.lastSyncTime = Date.now()
        this.discoveredDevices.push(info)
        Logger.info(TAG, 'Device discovered: ' + device.deviceName)
      })
      let discoverParam: DiscoverParam = {
        discoverTargetType: 1
      }
      this.deviceManager.startDiscovering(discoverParam)
      Logger.info(TAG, 'Device discovery started')
    } catch (err) {
      Logger.error(TAG, 'Failed to start device discovery: ' + JSON.stringify(err))
    }
  }

  stopDiscoverDevices(): void {
    if (this.deviceManager !== null) {
      try {
        this.deviceManager.stopDiscovering()
        Logger.info(TAG, 'Device discovery stopped')
      } catch (err) {
        Logger.error(TAG, 'Failed to stop discovery: ' + JSON.stringify(err))
      }
    }
  }

  generateSessionId(): string {
    return distributedDataObject.genSessionId()
  }
}
