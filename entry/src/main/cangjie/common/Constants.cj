const APP_NAME: string = 'NovaTask'
const APP_DOMAIN: number = 0xF000

const API_BASE_URL: string = 'https://api.novatask.example.com/v1'
const API_ENDPOINT_DECOMPOSE: string = '/agent/decompose'
const API_ENDPOINT_EXECUTE: string = '/agent/execute'
const API_TIMEOUT_MS: number = 30000

const MAX_RETRY_COUNT: number = 3
const RETRY_DELAY_MS: number = 1000

const DISTRIBUTED_SESSION_ID: string = 'novatask_sync_session'
const PREFS_STORE_NAME: string = 'novatask_prefs'
const PREFS_KEY_TASKS: string = 'task_list'

export { APP_NAME, APP_DOMAIN, API_BASE_URL, API_ENDPOINT_DECOMPOSE, API_ENDPOINT_EXECUTE, API_TIMEOUT_MS, MAX_RETRY_COUNT, RETRY_DELAY_MS, DISTRIBUTED_SESSION_ID, PREFS_STORE_NAME, PREFS_KEY_TASKS }
