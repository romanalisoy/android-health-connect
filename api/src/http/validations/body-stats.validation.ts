import {NextFunction, Request, Response} from "express";
import Joi from "joi";
import ValidationException from "../../core/exceptions/validation.exception";

const measurementField = Joi.number()
    .min(0)
    .max(500)
    .allow(null)
    .messages({
        'number.base': 'Must be a number',
        'number.min': 'Value must be at least 0',
        'number.max': 'Value cannot exceed 500'
    });

const updateBodyStatsSchema = Joi.object({
    waist: measurementField,
    neck: measurementField,
    chest: measurementField,
    shoulders: measurementField,
    right_arm: measurementField,
    left_arm: measurementField,
    right_forearm: measurementField,
    left_forearm: measurementField,
    hips: measurementField,
    right_thigh: measurementField,
    left_thigh: measurementField,
    right_calve: measurementField,
    left_calve: measurementField
}).min(1).messages({
    'object.min': 'At least one field is required'
});

export async function updateBodyStatsValidation(request: Request, response: Response, next: NextFunction) {
    const {error} = updateBodyStatsSchema.validate(request.body, {abortEarly: false});

    if (error) {
        throw new ValidationException(error);
    }

    next();
}
