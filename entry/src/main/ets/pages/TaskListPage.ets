import { TaskData, TaskCategory, TaskPriority, TaskStatus } from '../model/TaskData'
import { TaskListViewModel } from '../viewmodel/TaskListViewModel'
import { TaskRepository } from '../manager/TaskRepository'
import { APP_NAME } from '../common/Constants'

const CATEGORY_TABS: string[] = ['All', 'Work', 'Personal', 'Study', 'Health', 'Other']

@Component
export struct TaskListPage {
  @Consume('navStack') navStack: NavPathStack
  @State viewModel: TaskListViewModel = new TaskListViewModel()
  @State taskList: TaskData[] = []
  @State selectedTab: number = 0
  @State isLoading: boolean = false
  @State showCreateDialog: boolean = false
  @State showAgentDialog: boolean = false
  @State newTaskTitle: string = ''
  @State newTaskCategory: number = 1
  @State newGoalText: string = ''
  @State goalCategory: number = 1
  @State syncStatusText: string = ''

  aboutToAppear(): void {
    TaskRepository.getInstance().init(this.getUIContext().getHostContext() as Context)
    this.refreshTasks()
  }

  private refreshTasks(): void {
    this.viewModel.selectCategory(this.selectedTab)
    this.taskList = this.viewModel.taskList.slice()
    this.isLoading = this.viewModel.isLoading
  }

  build() {
    Column() {
      this.titleBar()
      this.categoryTabs()
      if (this.isLoading) {
        this.loadingView()
      } else if (this.taskList.length === 0) {
        this.emptyView()
      } else {
        this.taskListView()
      }
      this.fabButtons()
      this.syncStatusBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  titleBar() {
    Row() {
      Text(APP_NAME)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
      Blank()
      Text('\u2699')
        .fontSize(24)
        .fontColor('#333333')
        .onClick(() => {
          this.navStack.pushPath({ name: 'Settings' })
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  categoryTabs() {
    Tabs({ index: this.selectedTab }) {
      ForEach(CATEGORY_TABS, (tabName: string, index: number) => {
        TabContent() {
          Column()
        }
        .tabBar(tabName)
      }, (tabName: string, index: number) => tabName)
    }
    .barMode(BarMode.Scrollable)
    .onChange((index: number) => {
      this.selectedTab = index
      this.viewModel.selectCategory(index)
      this.taskList = this.viewModel.taskList.slice()
    })
    .width('100%')
    .height(48)
  }

  @Builder
  loadingView() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color('#4F6EF7')
      Text('Loading...')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  emptyView() {
    Column() {
      Text('No tasks yet')
        .fontSize(18)
        .fontColor('#666666')
      Text('Tap + to create a task or use Agent to decompose a goal')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  taskListView() {
    List({ space: 8 }) {
      ForEach(this.taskList, (task: TaskData) => {
        ListItem() {
          this.taskItem(task)
        }
      }, (task: TaskData) => task.id)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
    .divider({ strokeWidth: 1, color: '#EEEEEE' })
  }

  @Builder
  taskItem(task: TaskData) {
    Row() {
      Column() {
        Row() {
          Text(task.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(task.status === TaskStatus.COMPLETED ? '#999999' : '#1A1A1A')
            .decoration({ 
              type: task.status === TaskStatus.COMPLETED 
                ? TextDecorationType.LineThrough 
                : TextDecorationType.None 
            })
          if (task.isAgentDriven) {
            Text('Agent')
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor('#4F6EF7')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 8 })
          }
        }
        Text(TaskData.categoryToString(task.category) + ' | ' + TaskData.priorityToString(task.priority))
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Blank()

      this.priorityBadge(task.priority)
      Checkbox()
        .select(task.status === TaskStatus.COMPLETED)
        .onChange((checked: boolean) => {
          this.viewModel.toggleTaskStatus(task.id)
          this.refreshTasks()
        })
        .width(24)
        .height(24)
    }
    .width('100%')
    .padding(12)
    .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.1)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navStack.pushPath({ name: 'TaskDetail', param: task.id })
    })
  }

  @Builder
  priorityBadge(priority: TaskPriority) {
    Text(TaskData.priorityToString(priority))
      .fontSize(10)
      .fontColor(Color.White)
      .backgroundColor(this.priorityColor(priority))
      .borderRadius(8)
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .margin({ right: 8 })
  }

  private priorityColor(priority: TaskPriority): ResourceColor {
    switch (priority) {
      case TaskPriority.URGENT:
        return '#F44336'
      case TaskPriority.HIGH:
        return $r('app.color.priority_high')
      case TaskPriority.MEDIUM:
        return $r('app.color.priority_medium')
      case TaskPriority.LOW:
        return $r('app.color.priority_low')
      default:
        return $r('app.color.priority_medium')
    }
  }

  @Builder
  fabButtons() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(28)
          .fontColor(Color.White)
      }
      .width(56)
      .height(56)
      .backgroundColor('#4F6EF7')
      .borderRadius(28)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .shadow({
        radius: 16,
        color: 'rgba(0,0,0,0.15)',
        offsetX: 0,
        offsetY: 4
      })
      .onClick(() => {
        this.showCreateDialog = true
      })

      Button({ type: ButtonType.Circle }) {
        Text('A')
          .fontSize(20)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(56)
      .height(56)
      .backgroundColor($r('app.color.agent_primary'))
      .borderRadius(28)
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .shadow({
        radius: 16,
        color: 'rgba(0,0,0,0.15)',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ left: 16 })
      .onClick(() => {
        this.showAgentDialog = true
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
    .padding({ right: 24, bottom: 16 })
  }

  @Builder
  syncStatusBar() {
    if (this.syncStatusText.length > 0) {
      Row() {
        LoadingProgress()
          .width(16)
          .height(16)
          .color('#4F6EF7')
        Text(this.syncStatusText)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 8 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 16 })
      .backgroundColor('#E8EAF6')
    }
  }
}
