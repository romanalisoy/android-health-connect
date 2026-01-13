import type {Request, Response} from "express";

export interface Store {
    request: Request;
    response: Response;
}
