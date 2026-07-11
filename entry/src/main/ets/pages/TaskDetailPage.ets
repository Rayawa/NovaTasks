import { TaskData, TaskCategory, TaskPriority, TaskStatus } from '../model/TaskData'
import { AgentStep, StepStatus } from '../model/AgentStep'
import { TaskDetailViewModel } from '../viewmodel/TaskDetailViewModel'

@Component
export struct TaskDetailPage {
  @Consume('navStack') navStack: NavPathStack
  @State viewModel: TaskDetailViewModel = new TaskDetailViewModel()
  @State taskTitle: string = ''
  @State taskDescription: string = ''
  @State taskStatus: TaskStatus = TaskStatus.PENDING
  @State taskPriority: TaskPriority = TaskPriority.MEDIUM
  @State agentSteps: AgentStep[] = []
  @State isAgentRunning: boolean = false
  @State isDistributedShared: boolean = false
  @State subTasks: TaskData[] = []
  @State taskId: string = ''

  aboutToAppear(): void {
    let paramsArray: string[] = this.navStack.getParamByName('TaskDetail') as string[]
    if (paramsArray !== null && paramsArray !== undefined && paramsArray.length > 0) {
      this.taskId = paramsArray[0]
    }
    if (this.taskId.length > 0) {
      this.viewModel.loadTask(this.taskId)
      this.syncFromViewModel()
    }
  }

  private syncFromViewModel(): void {
    if (this.viewModel.task !== null) {
      let task = this.viewModel.task as TaskData
      this.taskTitle = task.title
      this.taskDescription = task.description
      this.taskStatus = task.status
      this.taskPriority = task.priority
      this.agentSteps = this.viewModel.agentSteps.slice()
      this.isAgentRunning = this.viewModel.isAgentRunning
      this.isDistributedShared = this.viewModel.isDistributedShared
      this.subTasks = this.viewModel.getSubTasks()
    }
  }

  build() {
    Column() {
      this.detailHeader()
      Scroll() {
        Column({ space: 16 }) {
          this.taskInfoCard()
          if (this.agentSteps.length > 0) {
            this.agentPanel()
          }
          if (this.subTasks.length > 0) {
            this.subTaskList()
          }
          this.actionButtons()
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  detailHeader() {
    Row() {
      Text('\u2190')
        .fontSize(24)
        .fontColor('#333333')
        .onClick(() => {
          this.navStack.pop()
        })
      Text('Task Detail')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .margin({ left: 12 })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
    .backgroundColor(Color.White)
  }

  @Builder
  taskInfoCard() {
    Column({ space: 12 }) {
      Row() {
        Text('Title:')
          .fontSize(14)
          .fontColor('#666666')
          .width(80)
        TextInput({ text: this.taskTitle })
          .fontSize(16)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .onChange((value: string) => {
            this.taskTitle = value
          })
          .onBlur(() => {
            this.viewModel.updateTaskTitle(this.taskTitle)
          })
      }

      Row() {
        Text('Description:')
          .fontSize(14)
          .fontColor('#666666')
          .width(80)
        TextInput({ text: this.taskDescription })
          .fontSize(14)
          .fontColor('#1A1A1A')
          .layoutWeight(1)
          .onChange((value: string) => {
            this.taskDescription = value
          })
          .onBlur(() => {
            this.viewModel.updateTaskDescription(this.taskDescription)
          })
      }

      Row() {
        Text('Priority:')
          .fontSize(14)
          .fontColor('#666666')
          .width(80)
        Row() {
          Button('Low')
            .fontSize(12)
            .fontColor(this.taskPriority === TaskPriority.LOW ? Color.White : '#666666')
            .backgroundColor(this.taskPriority === TaskPriority.LOW ? $r('app.color.priority_low') : Color.Transparent)
            .onClick(() => {
              this.taskPriority = TaskPriority.LOW
              this.viewModel.updateTaskPriority(TaskPriority.LOW)
            })
          Button('Med')
            .fontSize(12)
            .fontColor(this.taskPriority === TaskPriority.MEDIUM ? Color.White : '#666666')
            .backgroundColor(this.taskPriority === TaskPriority.MEDIUM ? $r('app.color.priority_medium') : Color.Transparent)
            .onClick(() => {
              this.taskPriority = TaskPriority.MEDIUM
              this.viewModel.updateTaskPriority(TaskPriority.MEDIUM)
            })
          Button('High')
            .fontSize(12)
            .fontColor(this.taskPriority === TaskPriority.HIGH ? Color.White : '#666666')
            .backgroundColor(this.taskPriority === TaskPriority.HIGH ? $r('app.color.priority_high') : Color.Transparent)
            .onClick(() => {
              this.taskPriority = TaskPriority.HIGH
              this.viewModel.updateTaskPriority(TaskPriority.HIGH)
            })
          Button('Urgent')
            .fontSize(12)
            .fontColor(this.taskPriority === TaskPriority.URGENT ? Color.White : '#666666')
            .backgroundColor(this.taskPriority === TaskPriority.URGENT ? '#F44336' : Color.Transparent)
            .onClick(() => {
              this.taskPriority = TaskPriority.URGENT
              this.viewModel.updateTaskPriority(TaskPriority.URGENT)
            })
        }
      }

      Row() {
        Text('Status:')
          .fontSize(14)
          .fontColor('#666666')
          .width(80)
        Text(TaskData.statusToString(this.taskStatus))
          .fontSize(14)
          .fontColor(this.statusColor(this.taskStatus))
          .fontWeight(FontWeight.Medium)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  agentPanel() {
    Column({ space: 8 }) {
      Row() {
        Text('Agent Steps')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        Blank()
        if (this.isAgentRunning) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color($r('app.color.agent_primary'))
        }
      }

      ForEach(this.agentSteps, (step: AgentStep) => {
        Row() {
          Text(step.stepIndex.toString())
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor(this.stepStatusColor(step.status))
            .borderRadius(8)
            .width(20)
            .height(20)
            .textAlign(TextAlign.Center)
            .margin({ right: 8 })

          Text(step.action)
            .fontSize(14)
            .fontColor('#1A1A1A')
            .layoutWeight(1)

          Text(AgentStep.statusToString(step.status))
            .fontSize(12)
            .fontColor(this.stepStatusColor(step.status))
        }
        .width('100%')
        .padding(8)
        .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }, (step: AgentStep) => step.id)

      if (!this.isAgentRunning && this.taskStatus !== TaskStatus.COMPLETED) {
        Button('Execute Agent Steps')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.agent_primary'))
          .borderRadius(8)
          .width('100%')
          .onClick(() => {
            this.viewModel.startAgentExecution()
            this.isAgentRunning = true
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .backgroundColor('#F3E5F5')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  subTaskList() {
    Column({ space: 8 }) {
      Text('Sub-Tasks')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')

      ForEach(this.subTasks, (subTask: TaskData) => {
        Row() {
          Checkbox()
            .select(subTask.status === TaskStatus.COMPLETED)
            .width(20)
            .height(20)
          Text(subTask.title)
            .fontSize(14)
            .fontColor(subTask.status === TaskStatus.COMPLETED ? '#999999' : '#1A1A1A')
            .layoutWeight(1)
            .decoration({ 
              type: subTask.status === TaskStatus.COMPLETED 
                ? TextDecorationType.LineThrough 
                : TextDecorationType.None 
            })
          Text(TaskData.statusToString(subTask.status))
            .fontSize(12)
            .fontColor(this.statusColor(subTask.status))
        }
        .width('100%')
        .padding(8)
        .backgroundBlurStyle(BlurStyle.COMPONENT_THIN)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }, (subTask: TaskData) => subTask.id)
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  actionButtons() {
    Column({ space: 8 }) {
      if (this.taskStatus === TaskStatus.PENDING) {
        Button('Start Task')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#4F6EF7')
          .borderRadius(8)
          .width('100%')
          .onClick(() => {
            this.viewModel.updateTaskStatus(TaskStatus.IN_PROGRESS)
            this.taskStatus = TaskStatus.IN_PROGRESS
          })
      }

      if (this.taskStatus === TaskStatus.IN_PROGRESS) {
        Button('Complete Task')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .width('100%')
          .onClick(() => {
            this.viewModel.updateTaskStatus(TaskStatus.COMPLETED)
            this.taskStatus = TaskStatus.COMPLETED
          })
      }

      Button('Share to Distributed Devices')
        .fontSize(14)
        .fontColor(this.isDistributedShared ? '#999999' : Color.White)
        .backgroundColor(this.isDistributedShared ? '#EEEEEE' : $r('app.color.distributed_primary'))
        .borderRadius(8)
        .width('100%')
        .enabled(!this.isDistributedShared)
        .onClick(() => {
          this.viewModel.shareToDistributed()
          this.isDistributedShared = true
        })

      Button('Delete Task')
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor('#F44336')
        .borderRadius(8)
        .width('100%')
        .onClick(() => {
          this.viewModel.deleteTask()
          this.navStack.pop()
        })
    }
    .width('100%')
    .padding(16)
  }

  private statusColor(status: TaskStatus): ResourceColor {
    switch (status) {
      case TaskStatus.PENDING:
        return $r('app.color.status_pending')
      case TaskStatus.IN_PROGRESS:
        return $r('app.color.status_in_progress')
      case TaskStatus.COMPLETED:
        return '#4CAF50'
      case TaskStatus.CANCELLED:
        return $r('app.color.status_cancelled')
      case TaskStatus.FAILED:
        return '#F44336'
      default:
        return $r('app.color.status_pending')
    }
  }

  private stepStatusColor(status: StepStatus): ResourceColor {
    switch (status) {
      case StepStatus.PENDING:
        return $r('app.color.status_pending')
      case StepStatus.RUNNING:
        return $r('app.color.status_in_progress')
      case StepStatus.SUCCESS:
        return '#4CAF50'
      case StepStatus.FAILED:
        return '#F44336'
      case StepStatus.SKIPPED:
        return $r('app.color.status_cancelled')
      default:
        return $r('app.color.status_pending')
    }
  }
}
