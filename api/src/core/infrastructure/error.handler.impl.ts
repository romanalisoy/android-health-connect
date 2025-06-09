import {Request, Response, NextFunction} from 'express';
import ValidationError from "../exceptions/validation.exception";

export default function (err: Error, req: Request, res: Response, next: NextFunction) {
    if (err instanceof ValidationError) {
        return res.status(err.statusCode).json({
            success: false,
            message: err.message,
            errors: err.errors,
        });
    }

    return res.status(500).json({
        status: 'error',
        statusCode: 500,
        message: err.message || 'Internal Server Error',
    });
};
