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

const updateProfileSchema = Joi.object({
    full_name: Joi.string()
        .min(2)
        .max(100)
        .messages({
            'string.min': 'Full name must be at least 2 characters',
            'string.max': 'Full name cannot exceed 100 characters'
        }),
    email: Joi.string()
        .email()
        .messages({
            'string.email': 'Invalid email format'
        }),
    birthdate: Joi.date()
        .iso()
        .max('now')
        .messages({
            'date.base': 'Invalid date format',
            'date.max': 'Birthdate cannot be in the future'
        })
}).min(1).messages({
    'object.min': 'At least one field is required'
});

const changePasswordSchema = Joi.object({
    current_password: Joi.string()
        .required()
        .messages({
            'any.required': 'Current password is required',
            'string.empty': 'Current password cannot be empty'
        }),
    new_password: Joi.string()
        .min(6)
        .required()
        .messages({
            'string.min': 'New password must be at least 6 characters',
            'any.required': 'New password is required',
            'string.empty': 'New password cannot be empty'
        }),
    password_confirmation: Joi.string()
        .valid(Joi.ref('new_password'))
        .required()
        .messages({
            'any.only': 'Password confirmation does not match',
            'any.required': 'Password confirmation is required',
            'string.empty': 'Password confirmation cannot be empty'
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

export async function updateProfileValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = updateProfileSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}

export async function changePasswordValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = changePasswordSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}
