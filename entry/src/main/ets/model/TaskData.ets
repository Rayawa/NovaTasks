import { util } from '@kit.ArkTS'
import { AgentStep } from './AgentStep'

export enum TaskCategory {
  WORK = 0,
  PERSONAL = 1,
  STUDY = 2,
  HEALTH = 3,
  OTHER = 4
}

export enum TaskPriority {
  LOW = 0,
  MEDIUM = 1,
  HIGH = 2,
  URGENT = 3
}

export enum TaskStatus {
  PENDING = 0,
  IN_PROGRESS = 1,
  COMPLETED = 2,
  CANCELLED = 3,
  FAILED = 4
}

interface TaskDataJson {
  id: string
  title: string
  description: string
  category: TaskCategory
  priority: TaskPriority
  status: TaskStatus
  isAgentDriven: boolean
  parentTaskId: string
  createdAt: number
  updatedAt: number
  completedAt: number
}

@ObservedV2
export class TaskData {
  @Trace id: string = util.generateRandomUUID(true)
  @Trace title: string = ''
  @Trace description: string = ''
  @Trace category: TaskCategory = TaskCategory.WORK
  @Trace priority: TaskPriority = TaskPriority.MEDIUM
  @Trace status: TaskStatus = TaskStatus.PENDING
  @Trace isAgentDriven: boolean = false
  @Trace agentSteps: AgentStep[] = []
  @Trace parentTaskId: string = ''
  @Trace createdAt: number = Date.now()
  @Trace updatedAt: number = Date.now()
  @Trace completedAt: number = 0

  static categoryToString(cat: TaskCategory): string {
    switch (cat) {
      case TaskCategory.WORK:
        return 'Work'
      case TaskCategory.PERSONAL:
        return 'Personal'
      case TaskCategory.STUDY:
        return 'Study'
      case TaskCategory.HEALTH:
        return 'Health'
      case TaskCategory.OTHER:
        return 'Other'
      default:
        return 'Other'
    }
  }

  static priorityToString(pri: TaskPriority): string {
    switch (pri) {
      case TaskPriority.LOW:
        return 'Low'
      case TaskPriority.MEDIUM:
        return 'Medium'
      case TaskPriority.HIGH:
        return 'High'
      case TaskPriority.URGENT:
        return 'Urgent'
      default:
        return 'Medium'
    }
  }

  static statusToString(status: TaskStatus): string {
    switch (status) {
      case TaskStatus.PENDING:
        return 'Pending'
      case TaskStatus.IN_PROGRESS:
        return 'In Progress'
      case TaskStatus.COMPLETED:
        return 'Completed'
      case TaskStatus.CANCELLED:
        return 'Cancelled'
      case TaskStatus.FAILED:
        return 'Failed'
      default:
        return 'Pending'
    }
  }

  toJsonObject(): TaskDataJson {
    let obj: TaskDataJson = {
      id: this.id,
      title: this.title,
      description: this.description,
      category: this.category,
      priority: this.priority,
      status: this.status,
      isAgentDriven: this.isAgentDriven,
      parentTaskId: this.parentTaskId,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      completedAt: this.completedAt
    }
    return obj
  }
}
