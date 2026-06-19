import { TaskListPage } from './TaskListPage'
import { TaskDetailPage } from './TaskDetailPage'
import { SettingsPage } from './SettingsPage'

@Entry
@Component
struct Index {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack()

  @Builder
  pageMap(name: string, params: Object) {
    if (name === 'TaskDetail') {
      TaskDetailPage()
    } else if (name === 'Settings') {
      SettingsPage()
    }
  }

  build() {
    Navigation(this.navStack) {
      TaskListPage()
    }
    .navDestination(this.pageMap)
    .mode(NavigationMode.Stack)
  }
}
