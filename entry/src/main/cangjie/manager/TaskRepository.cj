import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'
import { Logger } from '../common/Logger'
import { PREFS_STORE_NAME, PREFS_KEY_TASKS } from '../common/Constants'
import { TaskData, TaskCategory, TaskPriority, TaskStatus } from '../model/TaskData'

const TAG: string = 'TaskRepository'

export class TaskRepository {
  private static instance: TaskRepository | null = null
  private prefs: preferences.Preferences | null = null
  private tasks: TaskData[] = []

  static getInstance(): TaskRepository {
    if (TaskRepository.instance === null) {
      TaskRepository.instance = new TaskRepository()
    }
    return TaskRepository.instance
  }

  async init(context: Context): Promise<void> {
    try {
      this.prefs = await preferences.getPreferences(context, PREFS_STORE_NAME)
      await this.loadFromPrefs()
      Logger.info(TAG, 'TaskRepository initialized')
    } catch (err) {
      Logger.error(TAG, 'Failed to init preferences: ' + JSON.stringify(err))
    }
  }

  private async loadFromPrefs(): Promise<void> {
    if (this.prefs === null) {
      return
    }
    try {
      let data = await this.prefs.get(PREFS_KEY_TASKS, '[]')
      if (typeof data === 'string') {
        this.tasks = this.parseTasks(data)
        Logger.info(TAG, 'Loaded ' + this.tasks.length.toString() + ' tasks from prefs')
      }
    } catch (err) {
      Logger.error(TAG, 'Failed to load tasks: ' + JSON.stringify(err))
    }
  }

  private async saveToPrefs(): Promise<void> {
    if (this.prefs === null) {
      return
    }
    try {
      let json = JSON.stringify(this.tasks.map((task: TaskData) => task.toJsonObject()))
      await this.prefs.put(PREFS_KEY_TASKS, json)
      await this.prefs.flush()
      Logger.info(TAG, 'Saved ' + this.tasks.length.toString() + ' tasks to prefs')
    } catch (err) {
      Logger.error(TAG, 'Failed to save tasks: ' + JSON.stringify(err))
    }
  }

  private parseTasks(json: string): TaskData[] {
    let parsed: object[] = JSON.parse(json) as object[]
    let result: TaskData[] = []
    for (let i = 0; i < parsed.length; i++) {
      let obj = parsed[i]
      let task = new TaskData()
      let record = obj as Record<string, Object>
      task.id = (record['id'] as string) || ''
      task.title = (record['title'] as string) || ''
      task.description = (record['description'] as string) || ''
      task.category = (record['category'] as TaskCategory) || TaskCategory.OTHER
      task.priority = (record['priority'] as TaskPriority) || TaskPriority.MEDIUM
      task.status = (record['status'] as TaskStatus) || TaskStatus.PENDING
      task.isAgentDriven = (record['isAgentDriven'] as boolean) || false
      task.parentTaskId = (record['parentTaskId'] as string) || ''
      task.createdAt = (record['createdAt'] as number) || 0
      task.updatedAt = (record['updatedAt'] as number) || 0
      task.completedAt = (record['completedAt'] as number) || 0
      result.push(task)
    }
    return result
  }

  getAllTasks(): TaskData[] {
    return this.tasks.slice()
  }

  getTasksByCategory(category: TaskCategory): TaskData[] {
    return this.tasks.filter((task: TaskData) => task.category === category)
  }

  getTaskById(id: string): TaskData | null {
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id === id) {
        return this.tasks[i]
      }
    }
    return null
  }

  getSubTasks(parentId: string): TaskData[] {
    return this.tasks.filter((task: TaskData) => task.parentTaskId === parentId)
  }

  async addTask(task: TaskData): Promise<void> {
    this.tasks.push(task)
    await this.saveToPrefs()
    Logger.info(TAG, 'Task added: ' + task.title)
  }

  async updateTask(task: TaskData): Promise<void> {
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id === task.id) {
        this.tasks[i] = task
        task.updatedAt = Date.now()
        break
      }
    }
    await this.saveToPrefs()
    Logger.info(TAG, 'Task updated: ' + task.title)
  }

  async deleteTask(id: string): Promise<void> {
    this.tasks = this.tasks.filter((task: TaskData) => task.id !== id)
    for (let i = this.tasks.length - 1; i >= 0; i--) {
      if (this.tasks[i].parentTaskId === id) {
        this.tasks.splice(i, 1)
      }
    }
    await this.saveToPrefs()
    Logger.info(TAG, 'Task deleted: ' + id)
  }

  async setTaskStatus(id: string, status: TaskStatus): Promise<void> {
    for (let i = 0; i < this.tasks.length; i++) {
      if (this.tasks[i].id === id) {
        this.tasks[i].status = status
        this.tasks[i].updatedAt = Date.now()
        if (status === TaskStatus.COMPLETED) {
          this.tasks[i].completedAt = Date.now()
        }
        break
      }
    }
    await this.saveToPrefs()
    Logger.info(TAG, 'Task status updated: ' + id)
  }
}
