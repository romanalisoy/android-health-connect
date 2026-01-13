import {AsyncLocalStorage} from 'async_hooks'
import {Request, Response, NextFunction} from 'express'
import type {Store} from "../../../types/context";

const asyncLocal = new AsyncLocalStorage<Store>()

export function contextMiddleware(request: Request, response: Response, next: NextFunction) {
    asyncLocal.run({
            request,
            response
        },
        () => next()
    )
}

export function request(): Request {
    const store = asyncLocal.getStore()

    if (!store) throw new Error('Request context not found')

    function input<T = any>(key: string, defaultValue: T | null = null): T | null {
        const req = store.request
        if (req.body && key in req.body) return req.body[key]
    }

    function queryParams<T = any>(key: string, defaultValue: T | null = null): T | null {
        const req = store.request
        if (req.query && key in req.query) return (req.query as any)[key]
        return defaultValue
    }

    function getHeader(name: string, defaultValue: string | null = null): string | string[] | null {
        const val = store.request.headers[name.toLowerCase()]
        return typeof val === 'string' ? val : defaultValue
    }

    function filters(): any {
        return queryParams('filters', undefined)
    }

    function page(): number {
        return parseInt(String(queryParams('page', 1)));
    }

    function limit(): number {
        return parseInt(String(queryParams('limit', 10)));
    }

    // @ts-ignore
    return {
        ...store.request,
        input,
        getHeader,
        queryParams,
        filters,
        page,
        limit,
    }

}

