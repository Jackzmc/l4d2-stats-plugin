
export function api404(error: string, message: string): Response {
  return apiError(404, error, message) 
}
export function apiError(status: number = 500, error: string, message: string): Response {
  return apiJson({ error, message }, status)
}

export function apiJson(body: object, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json', ...headers} })
}