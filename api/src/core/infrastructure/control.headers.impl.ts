import {Request, Response, NextFunction} from 'express';

export default function (request: Request, response: Response, next: NextFunction) {
    if (request.header('Accept') !== 'application/json') request.headers.accept = 'application/json';
    next();
}