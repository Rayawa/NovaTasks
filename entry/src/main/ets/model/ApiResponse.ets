export class ApiResponse {
  code: number = -1
  message: string = ''
  data: string = ''

  isSuccess(): boolean {
    return this.code >= 200 && this.code < 300
  }

  static create(code: number, message: string, data: string): ApiResponse {
    let resp = new ApiResponse()
    resp.code = code
    resp.message = message
    resp.data = data
    return resp
  }
}
