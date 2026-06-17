import { http } from '@kit.NetworkKit'
import { Logger } from '../common/Logger'
import { API_BASE_URL, API_TIMEOUT_MS } from '../common/Constants'
import { ApiResponse } from '../model/ApiResponse'

const TAG: string = 'NetworkService'

export class NetworkService {
  private static instance: NetworkService | null = null
  private baseUrl: string = API_BASE_URL

  static getInstance(): NetworkService {
    if (NetworkService.instance === null) {
      NetworkService.instance = new NetworkService()
    }
    return NetworkService.instance
  }

  async post(endpoint: string, body: string): Promise<ApiResponse> {
    let httpRequest = http.createHttp()
    let url = this.baseUrl + endpoint
    try {
      Logger.info(TAG, 'POST request to: ' + url)
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: body,
        connectTimeout: API_TIMEOUT_MS,
        readTimeout: API_TIMEOUT_MS
      })
      let apiResp = new ApiResponse()
      apiResp.code = response.responseCode
      if (typeof response.result === 'string') {
        apiResp.data = response.result
        apiResp.message = 'Success'
      } else {
        apiResp.message = 'Invalid response format'
      }
      Logger.info(TAG, 'POST response code: ' + apiResp.code.toString())
      return apiResp
    } catch (err) {
      Logger.error(TAG, 'POST request failed: ' + JSON.stringify(err))
      let errResp = new ApiResponse()
      errResp.code = -1
      errResp.message = 'Network request failed'
      return errResp
    } finally {
      httpRequest.destroy()
    }
  }

  async get(endpoint: string): Promise<ApiResponse> {
    let httpRequest = http.createHttp()
    let url = this.baseUrl + endpoint
    try {
      Logger.info(TAG, 'GET request to: ' + url)
      let response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: API_TIMEOUT_MS,
        readTimeout: API_TIMEOUT_MS
      })
      let apiResp = new ApiResponse()
      apiResp.code = response.responseCode
      if (typeof response.result === 'string') {
        apiResp.data = response.result
        apiResp.message = 'Success'
      } else {
        apiResp.message = 'Invalid response format'
      }
      Logger.info(TAG, 'GET response code: ' + apiResp.code.toString())
      return apiResp
    } catch (err) {
      Logger.error(TAG, 'GET request failed: ' + JSON.stringify(err))
      let errResp = new ApiResponse()
      errResp.code = -1
      errResp.message = 'Network request failed'
      return errResp
    } finally {
      httpRequest.destroy()
    }
  }
}
