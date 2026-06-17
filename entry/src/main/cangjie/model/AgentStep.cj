export enum StepStatus {
  PENDING = 0,
  RUNNING = 1,
  SUCCESS = 2,
  FAILED = 3,
  SKIPPED = 4
}

interface AgentStepJson {
  id: string
  taskId: string
  stepIndex: number
  action: string
  status: StepStatus
  result: string
  retryCount: number
  maxRetry: number
}

export class AgentStep {
  id: string = ''
  taskId: string = ''
  stepIndex: number = 0
  action: string = ''
  status: StepStatus = StepStatus.PENDING
  result: string = ''
  retryCount: number = 0
  maxRetry: number = 3

  static statusToString(status: StepStatus): string {
    switch (status) {
      case StepStatus.PENDING:
        return 'Pending'
      case StepStatus.RUNNING:
        return 'Running'
      case StepStatus.SUCCESS:
        return 'Success'
      case StepStatus.FAILED:
        return 'Failed'
      case StepStatus.SKIPPED:
        return 'Skipped'
      default:
        return 'Pending'
    }
  }

  canRetry(): boolean {
    return this.status === StepStatus.FAILED && this.retryCount < this.maxRetry
  }

  toJsonObject(): AgentStepJson {
    let obj: AgentStepJson = {
      id: this.id,
      taskId: this.taskId,
      stepIndex: this.stepIndex,
      action: this.action,
      status: this.status,
      result: this.result,
      retryCount: this.retryCount,
      maxRetry: this.maxRetry
    }
    return obj
  }
}
