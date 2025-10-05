
export function api404(error: string, message: string): Response {
  return new Response(JSON.stringify({
    error,
    message
  }), { status: 400, headers: { 'Content-Type': 'application/json'} })
}