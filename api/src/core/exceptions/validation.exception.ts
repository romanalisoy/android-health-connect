import {ValidationError} from 'joi';

export default class ValidationException extends Error {
    public statusCode: number;
    public errors: Record<string, string[]>;

    constructor(validationError: ValidationError) {
        super();

        this.statusCode = 422;

        this.errors = validationError.details.reduce((acc: Record<string, string[]>, detail) => {
            const field = detail.path.join('.');
            const message = detail.message.replaceAll('"', '');

            if (!acc[field]) {
                acc[field] = [];
            }

            acc[field].push(message);
            return acc;
        }, {});


        const errorMessages: string[] = Object.values(this.errors).flat();
        this.message = `${errorMessages[0]}${errorMessages.length > 1 ? ` (and ${errorMessages.length - 1} more error${errorMessages.length - 1 > 1 ? 's' : ''})` : ''}`;

        Object.setPrototypeOf(this, ValidationException.prototype);
    }
}

