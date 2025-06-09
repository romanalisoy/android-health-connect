import BaseEntity from "../../database/entities/BaseEntity";
import {CustomHelpers, ValidationError} from "joi";

function isBaseEntityClass(validator: any): validator is typeof BaseEntity {
    return typeof validator === 'function' && validator.prototype instanceof BaseEntity;
}

export function existRule<T extends typeof BaseEntity>(validator: T | string, field: string = null) {
    return async (value: string, helpers: CustomHelpers) => {
        if (isBaseEntityClass(validator)) {
            const fieldName: string | number = field ?? helpers.state.path[0];
            const entity = await validator.repo()
                .find({where: {[fieldName]: value}});
            if (!entity.length) {
                throw new ValidationError(
                    `You have validation error in ${fieldName}`,
                    [{
                        type: 'any.invalid',
                        message: `The selected ${fieldName} is not exist.`,
                        path: helpers.state.path,
                    }],
                    value
                )
            }
        }
        return value;
    };
}