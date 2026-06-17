import { TaskData, TaskCategory, TaskPriority, TaskStatus } from '../model/TaskData'
import { AgentStep, StepStatus } from '../model/AgentStep'
import { TaskRepository } from '../manager/TaskRepository'
import { AgentManager } from '../manager/AgentManager'
import { DistributedManager } from '../manager/DistributedManager'
import { Logger } from '../common/Logger'

const TAG: string = 'TaskDetailVM'

export class TaskDetailViewModel {
  task: TaskData | null = null
  agentSteps: AgentStep[] = []
  isAgentRunning: boolean = false
  isDistributedShared: boolean = false
  errorMessage: string = ''

  private agentManager: AgentManager = AgentManager.getInstance()
  private distributedManager: DistributedManager = DistributedManager.getInstance()
  private repository: TaskRepository = TaskRepository.getInstance()

  loadTask(taskId: string): void {
    this.task = this.repository.getTaskById(taskId)
    if (this.task !== null) {
      this.agentSteps = this.task.agentSteps.slice()
      if (this.agentSteps.length === 0 && this.task.isAgentDriven) {
        this.agentSteps = this.agentManager.createAgentStepsForTask(this.task)
        this.task.agentSteps = this.agentSteps
      }
      Logger.info(TAG, 'Task loaded: ' + this.task.title)
    } else {
      this.errorMessage = 'Task not found'
      Logger.error(TAG, 'Task not found: ' + taskId)
    }
  }

  async updateTaskTitle(title: string): Promise<void> {
    if (this.task !== null) {
      this.task.title = title
      await this.repository.updateTask(this.task)
      Logger.info(TAG, 'Task title updated')
    }
  }

  async updateTaskDescription(description: string): Promise<void> {
    if (this.task !== null) {
      this.task.description = description
      await this.repository.updateTask(this.task)
      Logger.info(TAG, 'Task description updated')
    }
  }

  async updateTaskPriority(priority: TaskPriority): Promise<void> {
    if (this.task !== null) {
      this.task.priority = priority
      await this.repository.updateTask(this.task)
      Logger.info(TAG, 'Task priority updated')
    }
  }

  async updateTaskStatus(status: TaskStatus): Promise<void> {
    if (this.task !== null) {
      this.task.status = status
      await this.repository.setTaskStatus(this.task.id, status)
      this.task = this.repository.getTaskById(this.task.id)
      Logger.info(TAG, 'Task status updated')
    }
  }

  async startAgentExecution(): Promise<void> {
    if (this.task === null) {
      return
    }
    this.isAgentRunning = true
    try {
      await this.agentManager.executeAgentSteps(this.agentSteps, (step: AgentStep) => {
        for (let i = 0; i < this.agentSteps.length; i++) {
          if (this.agentSteps[i].id === step.id) {
            this.agentSteps[i] = step
            break
          }
        }
        if (this.task !== null) {
          this.task.agentSteps = this.agentSteps.slice()
          this.repository.updateTask(this.task)
        }
      })
      if (this.task !== null) {
        let allSuccess = true
        for (let i = 0; i < this.agentSteps.length; i++) {
          if (this.agentSteps[i].status !== StepStatus.SUCCESS) {
            allSuccess = false
            break
          }
        }
        if (allSuccess) {
          await this.updateTaskStatus(TaskStatus.COMPLETED)
        } else {
          await this.updateTaskStatus(TaskStatus.FAILED)
        }
      }
      Logger.info(TAG, 'Agent execution completed')
    } catch (err) {
      this.errorMessage = 'Agent execution failed'
      Logger.error(TAG, 'Agent execution error: ' + JSON.stringify(err))
    }
    this.isAgentRunning = false
  }

  async shareToDistributed(): Promise<void> {
    if (this.task === null) {
      return
    }
    try {
      let tasks = this.repository.getAllTasks()
      await this.distributedManager.createDistributedObject(tasks)
      await this.distributedManager.joinDefaultSession()
      this.isDistributedShared = true
      Logger.info(TAG, 'Task shared to distributed devices')
    } catch (err) {
      this.errorMessage = 'Failed to share task'
      Logger.error(TAG, 'Share error: ' + JSON.stringify(err))
    }
  }

  async deleteTask(): Promise<string> {
    if (this.task !== null) {
      let taskId = this.task.id
      await this.repository.deleteTask(taskId)
      Logger.info(TAG, 'Task deleted')
      return taskId
    }
    return ''
  }

  getSubTasks(): TaskData[] {
    if (this.task !== null) {
      return this.repository.getSubTasks(this.task.id)
    }
    return []
  }
}
