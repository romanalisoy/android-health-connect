import {NextFunction, Request, Response} from "express";
import Joi from "joi";
import ValidationException from "../../core/exceptions/validation.exception";

const permissionSchema = Joi.object({
    PERMISSION_NAME: Joi.any().required()
}).unknown(true);

export async function healthPermissionValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = permissionSchema.validate(request.params, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}
