import type {RequestHandler} from "express";

export type RouteHandler = RequestHandler | [new () => any, string];
export type Middleware = RequestHandler | RequestHandler[];
