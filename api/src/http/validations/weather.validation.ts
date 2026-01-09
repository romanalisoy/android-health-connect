import Joi from 'joi';
import {Request, Response, NextFunction} from 'express';
import ValidationException from "../../core/exceptions/validation.exception";

const getWeatherSchema = Joi.object({
    lat: Joi.number()
        .min(-90)
        .max(90)
        .required()
        .messages({
            'number.base': 'Latitude must be a number',
            'number.min': 'Latitude must be between -90 and 90',
            'number.max': 'Latitude must be between -90 and 90',
            'any.required': 'Latitude is required'
        }),
    lon: Joi.number()
        .min(-180)
        .max(180)
        .required()
        .messages({
            'number.base': 'Longitude must be a number',
            'number.min': 'Longitude must be between -180 and 180',
            'number.max': 'Longitude must be between -180 and 180',
            'any.required': 'Longitude is required'
        })
});

export async function getWeatherValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = getWeatherSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}
