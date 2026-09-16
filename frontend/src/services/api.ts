const API_URL = 'http://localhost:3000/api/v1'
const TOKEN_KEY = 'expenseflow_token'

interface ErrorResponse {
    error?: string
    errors?: string[]
}

export async function apiFetch(path: string, options: RequestInit = {}): Promise<Response> {
    const token = sessionStorage.getItem(TOKEN_KEY)
    const response = await fetch(`${API_URL}${path}`, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
            ...options.headers,
        },
    })

    if (response.status === 401) {
        const body = (await response.json().catch(() => ({}))) as ErrorResponse

        const message =
            body.errors?.join(', ') ??
            body.error ??
            'Your session has expired.'

        alert(message)

        setTimeout(() => {
            sessionStorage.clear()
            window.location.assign('/')
        }, 3000)
    }

    return response
}

export async function apiError(response: Response, fallback: string): Promise<Error> {
    const body = (await response.json().catch(() => ({}))) as ErrorResponse
    return new Error(body.errors?.join(', ') ?? body.error ?? fallback)
}