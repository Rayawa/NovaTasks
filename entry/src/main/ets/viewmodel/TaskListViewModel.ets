import { TaskData, TaskCategory, TaskPriority, TaskStatus } from '../model/TaskData'
import { AgentStep, StepStatus } from '../model/AgentStep'
import { DeviceInfo, SyncStatus } from '../model/DeviceInfo'
import { TaskRepository } from '../manager/TaskRepository'
import { AgentManager } from '../manager/AgentManager'
import { DistributedManager } from '../manager/DistributedManager'
import { Logger } from '../common/Logger'

const TAG: string = 'TaskListVM'

export class TaskListViewModel {
  taskList: TaskData[] = []
  isLoading: boolean = false
  selectedCategoryIndex: number = 0
  isDistributedSyncing: boolean = false
  distributedDevices: DeviceInfo[] = []
  errorMessage: string = ''

  private agentManager: AgentManager = AgentManager.getInstance()
  private distributedManager: DistributedManager = DistributedManager.getInstance()
  private repository: TaskRepository = TaskRepository.getInstance()

  async loadTasks(): Promise<void> {
    this.isLoading = true
    try {
      if (this.selectedCategoryIndex === 0) {
        this.taskList = this.repository.getAllTasks()
      } else {
        let category = this.indexToCategory(this.selectedCategoryIndex)
        this.taskList = this.repository.getTasksByCategory(category)
      }
      Logger.info(TAG, 'Loaded ' + this.taskList.length.toString() + ' tasks')
    } catch (err) {
      this.errorMessage = 'Failed to load tasks'
      Logger.error(TAG, 'Load tasks error: ' + JSON.stringify(err))
    }
    this.isLoading = false
  }

  async createTask(title: string, category: TaskCategory, priority: TaskPriority): Promise<TaskData> {
    let task = new TaskData()
    task.title = title
    task.category = category
    task.priority = priority
    task.status = TaskStatus.PENDING
    await this.repository.addTask(task)
    await this.loadTasks()
    Logger.info(TAG, 'Task created: ' + title)
    return task
  }

  async createAgentGoal(goal: string, category: TaskCategory): Promise<TaskData> {
    this.isLoading = true
    try {
      let parentTask = new TaskData()
      parentTask.title = goal
      parentTask.category = category
      parentTask.priority = TaskPriority.HIGH
      parentTask.isAgentDriven = true
      parentTask.status = TaskStatus.IN_PROGRESS
      await this.repository.addTask(parentTask)

      let subTasks = await this.agentManager.decomposeGoal(goal, category)
      for (let i = 0; i < subTasks.length; i++) {
        subTasks[i].parentTaskId = parentTask.id
        await this.repository.addTask(subTasks[i])
      }

      let steps = this.agentManager.createAgentStepsForTask(parentTask)
      parentTask.agentSteps = steps

      await this.loadTasks()
      Logger.info(TAG, 'Agent goal created with ' + subTasks.length.toString() + ' sub-tasks')
      this.isLoading = false
      return parentTask
    } catch (err) {
      this.errorMessage = 'Failed to create agent goal'
      Logger.error(TAG, 'Agent goal error: ' + JSON.stringify(err))
      this.isLoading = false
      return new TaskData()
    }
  }

  async toggleTaskStatus(taskId: string): Promise<void> {
    let task = this.repository.getTaskById(taskId)
    if (task !== null) {
      let newStatus = task.status === TaskStatus.COMPLETED ? TaskStatus.PENDING : TaskStatus.COMPLETED
      await this.repository.setTaskStatus(taskId, newStatus)
      await this.loadTasks()
      Logger.info(TAG, 'Task status toggled: ' + taskId)
    }
  }

  async deleteTask(taskId: string): Promise<void> {
    await this.repository.deleteTask(taskId)
    await this.loadTasks()
    Logger.info(TAG, 'Task deleted: ' + taskId)
  }

  selectCategory(index: number): void {
    this.selectedCategoryIndex = index
    this.loadTasks()
  }

  async startDistributedSync(): Promise<void> {
    this.isDistributedSyncing = true
    try {
      let tasks = this.repository.getAllTasks()
      await this.distributedManager.createDistributedObject(tasks)
      await this.distributedManager.joinDefaultSession()
      this.distributedManager.onDataChange((sessionId: string, fields: string[]) => {
        Logger.info(TAG, 'Distributed data changed from session: ' + sessionId)
        this.loadTasks()
      })
      this.distributedManager.onStatusChange((sessionId: string, networkId: string, status: string) => {
        Logger.info(TAG, 'Distributed status: ' + status)
      })
      Logger.info(TAG, 'Distributed sync started')
    } catch (err) {
      this.errorMessage = 'Failed to start distributed sync'
      Logger.error(TAG, 'Distributed sync error: ' + JSON.stringify(err))
    }
    this.isDistributedSyncing = false
  }

  async refreshDevices(): Promise<void> {
    this.distributedManager.discoverDevices()
    this.distributedDevices = this.distributedManager.getDiscoveredDevices()
  }

  private indexToCategory(index: number): TaskCategory {
    switch (index) {
      case 1:
        return TaskCategory.WORK
      case 2:
        return TaskCategory.PERSONAL
      case 3:
        return TaskCategory.STUDY
      case 4:
        return TaskCategory.HEALTH
      case 5:
        return TaskCategory.OTHER
      default:
        return TaskCategory.WORK
    }
  }
}
