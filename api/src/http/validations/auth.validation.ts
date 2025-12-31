import {NextFunction, Request, Response} from "express";
import Joi from "joi";
import ValidationException from "../../core/exceptions/validation.exception";

const loginSchema = Joi.object({
    email: Joi.string()
        .email()
        .required()
        .messages({
            'string.email': 'Invalid email format',
            'any.required': 'Email is required',
            'string.empty': 'Email cannot be empty'
        }),
    password: Joi.string()
        .min(6)
        .required()
        .messages({
            'string.min': 'Password must be at least 6 characters',
            'any.required': 'Password is required',
            'string.empty': 'Password cannot be empty'
        })
});

const refreshTokenSchema = Joi.object({
    refreshToken: Joi.string()
        .required()
        .messages({
            'any.required': 'Refresh token is required',
            'string.empty': 'Refresh token cannot be empty'
        })
});

const revokeTokenSchema = Joi.object({
    refreshToken: Joi.string()
        .required()
        .messages({
            'any.required': 'Refresh token is required',
            'string.empty': 'Refresh token cannot be empty'
        })
});

const updateFcmTokenSchema = Joi.object({
    fcmToken: Joi.string()
        .required()
        .messages({
            'any.required': 'FCM token is required',
            'string.empty': 'FCM token cannot be empty'
        })
});

export async function loginValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = loginSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}

export async function refreshTokenValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = refreshTokenSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}

export async function revokeTokenValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = revokeTokenSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}

export async function updateFcmTokenValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = updateFcmTokenSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}
