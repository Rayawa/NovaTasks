import { taskpool } from '@kit.ArkTS'
import { util } from '@kit.ArkTS'
import { Logger } from '../common/Logger'
import { API_ENDPOINT_DECOMPOSE, API_ENDPOINT_EXECUTE, MAX_RETRY_COUNT, RETRY_DELAY_MS } from '../common/Constants'
import { TaskData, TaskCategory, TaskPriority, TaskStatus } from '../model/TaskData'
import { AgentStep, StepStatus } from '../model/AgentStep'
import { NetworkService } from '../service/NetworkService'

const TAG: string = 'AgentManager'

interface DecomposeRequestBody {
  goal: string
  category: string
}

interface StepExecutionBody {
  taskId: string
  stepId: string
  action: string
}

@Concurrent
function executeStepInTaskPool(stepId: string, taskId: string, action: string): string {
  let stepAction = action
  let result = 'Step ' + stepId + ' executed: ' + stepAction
  return result
}

export class AgentManager {
  private static instance: AgentManager | null = null
  private networkService: NetworkService = NetworkService.getInstance()

  static getInstance(): AgentManager {
    if (AgentManager.instance === null) {
      AgentManager.instance = new AgentManager()
    }
    return AgentManager.instance
  }

  async decomposeGoal(goal: string, category: TaskCategory): Promise<TaskData[]> {
    Logger.info(TAG, 'Decomposing goal: ' + goal)
    try {
      let reqBody: DecomposeRequestBody = {
        goal: goal,
        category: TaskData.categoryToString(category)
      }
      let response = await this.networkService.post(
        API_ENDPOINT_DECOMPOSE,
        JSON.stringify(reqBody)
      )
      if (response.isSuccess()) {
        return this.parseDecomposedTasks(response.data, category)
      } else {
        Logger.warn(TAG, 'LLM decompose failed, using local fallback')
        return this.localFallbackDecompose(goal, category)
      }
    } catch (err) {
      Logger.error(TAG, 'Decompose error: ' + JSON.stringify(err))
      return this.localFallbackDecompose(goal, category)
    }
  }

  private parseDecomposedTasks(data: string, category: TaskCategory): TaskData[] {
    try {
      let parsed: object[] = JSON.parse(data) as object[]
      let tasks: TaskData[] = []
      for (let i = 0; i < parsed.length; i++) {
        let record = parsed[i] as Record<string, Object>
        let task = new TaskData()
        task.title = (record['title'] as string) || 'Sub-task ' + (i + 1).toString()
        task.description = (record['description'] as string) || ''
        task.category = category
        task.isAgentDriven = true
        task.status = TaskStatus.PENDING
        tasks.push(task)
      }
      return tasks
    } catch (err) {
      Logger.error(TAG, 'Parse decomposed tasks failed: ' + JSON.stringify(err))
      return []
    }
  }

  private localFallbackDecompose(goal: string, category: TaskCategory): TaskData[] {
    let steps = this.splitGoalToSteps(goal)
    let tasks: TaskData[] = []
    for (let i = 0; i < steps.length; i++) {
      let task = new TaskData()
      task.title = steps[i]
      task.description = 'Auto-generated sub-task for: ' + goal
      task.category = category
      task.priority = TaskPriority.MEDIUM
      task.isAgentDriven = true
      task.status = TaskStatus.PENDING
      tasks.push(task)
    }
    Logger.info(TAG, 'Local fallback generated ' + tasks.length.toString() + ' sub-tasks')
    return tasks
  }

  private splitGoalToSteps(goal: string): string[] {
    let parts = goal.split(/[，,;；.。！!？?]+/)
    let filtered: string[] = []
    for (let i = 0; i < parts.length; i++) {
      let trimmed = parts[i].trim()
      if (trimmed.length > 0) {
        filtered.push(trimmed)
      }
    }
    if (filtered.length === 0) {
      filtered = ['Step 1: ' + goal]
    }
    return filtered
  }

  async executeAgentSteps(steps: AgentStep[], onStepUpdate: (step: AgentStep) => void): Promise<void> {
    Logger.info(TAG, 'Executing ' + steps.length.toString() + ' agent steps')
    for (let i = 0; i < steps.length; i++) {
      let step = steps[i]
      step.status = StepStatus.RUNNING
      onStepUpdate(step)
      try {
        let task = new taskpool.Task(executeStepInTaskPool, step.id, step.taskId, step.action)
        let result = await taskpool.execute(task)
        step.result = result as string
        step.status = StepStatus.SUCCESS
        onStepUpdate(step)
        Logger.info(TAG, 'Step ' + step.stepIndex.toString() + ' succeeded')
      } catch (err) {
        step.retryCount += 1
        if (step.canRetry()) {
          Logger.warn(TAG, 'Step ' + step.stepIndex.toString() + ' failed, retrying...')
          i -= 1
          await this.delay(RETRY_DELAY_MS)
          continue
        }
        step.status = StepStatus.FAILED
        step.result = JSON.stringify(err)
        onStepUpdate(step)
        Logger.error(TAG, 'Step ' + step.stepIndex.toString() + ' failed permanently')
      }
    }
    Logger.info(TAG, 'All agent steps execution completed')
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve: Function) => {
      setTimeout(() => {
        resolve()
      }, ms)
    })
  }

  createAgentStepsForTask(task: TaskData): AgentStep[] {
    let steps: AgentStep[] = []
    let subTasks = this.splitGoalToSteps(task.title)
    for (let i = 0; i < subTasks.length; i++) {
      let step = new AgentStep()
      step.id = util.generateRandomUUID(true)
      step.taskId = task.id
      step.stepIndex = i
      step.action = subTasks[i]
      step.status = StepStatus.PENDING
      step.maxRetry = MAX_RETRY_COUNT
      steps.push(step)
    }
    return steps
  }
}
