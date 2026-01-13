import {NextFunction, Request, Response} from "express";
import Joi from "joi";
import ValidationException from "../../core/exceptions/validation.exception";

const PERMISSIONS = [
    'Weight',
    'Height',
    'BodyFat',
    'BodyWaterMass',
    'BoneMass',
    'LeanBodyMass',
    'BasalMetabolicRate'
] as const;

const paramsSchema = Joi.object({
    PERMISSION_NAME: Joi.string().valid(...PERMISSIONS).required()
});

const baseItemSchema = Joi.object({
    id: Joi.string()
        .guid({version: ['uuidv1', 'uuidv3', 'uuidv4', 'uuidv5']})
        .required(),
    dataOrigin: Joi.string().min(1).required(),
    time: Joi.number().integer().min(0).required(),
});

const schemasByPermission: Record<(typeof PERMISSIONS)[number], Joi.ObjectSchema> = {
    Weight: baseItemSchema.keys({
        weight: Joi.number().min(0).required()
    }),
    Height: baseItemSchema.keys({
        height: Joi.number().min(0).required()
    }),
    BodyFat: baseItemSchema.keys({
        percentage: Joi.number().min(0).max(100).required()
    }),
    BodyWaterMass: baseItemSchema.keys({
        mass: Joi.number().min(0).required()
    }),
    BoneMass: baseItemSchema.keys({
        mass: Joi.number().min(0).required()
    }),
    LeanBodyMass: baseItemSchema.keys({
        mass: Joi.number().min(0).required()
    }),
    BasalMetabolicRate: baseItemSchema.keys({
        basalMetabolicRate: Joi.number().min(0).required()
    }),
};

function buildBodySchema(permissionName: (typeof PERMISSIONS)[number]) {
    return Joi.object({
        data: Joi.array()
            .items(schemasByPermission[permissionName])
            .min(1)
            .unique('id')
            .required()
    });
}

export async function healthDataValidation(request: Request, response: Response, next: NextFunction) {
    const paramsResult = paramsSchema.validate(request.params, {abortEarly: false});
    if (paramsResult.error) {
        throw new ValidationException(paramsResult.error);
    }

    const permissionName = paramsResult.value.PERMISSION_NAME as (typeof PERMISSIONS)[number];
    const bodySchema = buildBodySchema(permissionName);
    const bodyResult = bodySchema.validate(request.body, {abortEarly: false});

    if (bodyResult.error) {
        throw new ValidationException(bodyResult.error);
    }

    next();
}
