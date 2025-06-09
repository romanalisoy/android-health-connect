import BaseEntity from "../../database/entities/BaseEntity";
import {CustomHelpers, ValidationError} from "joi";
import {SelectQueryBuilder} from "typeorm";

function isBaseEntityClass(validator: any): validator is typeof BaseEntity {
    return typeof validator === 'function' && validator.prototype instanceof BaseEntity;
}

export function duplicateRule<T extends typeof BaseEntity>(validator: T | string, fields: string[]) {
    return async (value: string, helpers: CustomHelpers) => {
        if (isBaseEntityClass(validator)) {
            const payload = helpers?.state?.ancestors[0];

            const validFields: string[] = fields.filter(field => payload[field] !== undefined && payload[field] !== null);

            if (validFields.length === 0) {
                return value;
            }

            const queryBuilder: SelectQueryBuilder<BaseEntity> = validator.repo().createQueryBuilder('entity');

            validFields.forEach((field: string, index: number) => {
                if (index === 0) {
                    queryBuilder.where(`entity.${field} = :${field}`, {[field]: payload[field]});
                } else {
                    queryBuilder.andWhere(`entity.${field} = :${field}`, {[field]: payload[field]});
                }
            });


            const existingRecord: BaseEntity = await queryBuilder.getOne();

            if (existingRecord) {
                throw new ValidationError(
                    `Duplicate record detected for fields: ${validFields.join(', ')}`,
                    [{
                        type: 'any.invalid',
                        message: `A record with the same ${validFields.join(', ')} already exists.`,
                        path: helpers.state.path,
                    }],
                    value
                );
            }
        }
        return value;
    };
}

