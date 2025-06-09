import {BaseEntity as TypeORMEntity, Equal, FindOptionsWhere, In, LessThan, LessThanOrEqual, Like, MoreThan, MoreThanOrEqual, Not, Repository} from 'typeorm';
import AppDataSource from "../../core/configs/datasource.config";
import {request} from "../../core/infrastructure/context.request.impl";

export default class BaseEntity extends TypeORMEntity {
    protected static repository: Repository<any>;
    protected static conditions: FindOptionsWhere<any>[] = [];
    protected static orConditions: FindOptionsWhere<any>[] = [];
    protected static orderOptions: { [key: string]: 'ASC' | 'DESC' } = {};
    protected static relations: string[] = [];
    protected static takeValue?: number;
    protected static skipValue?: number;

    public static repo<T extends BaseEntity>(this: new () => T): Repository<T> {
        return AppDataSource.getRepository(this);
    }

    public static exec<T extends typeof BaseEntity>(this: T): T {
        this.repository = AppDataSource.getRepository(this);
        this.conditions = [];
        this.orConditions = [];
        this.orderOptions = {};
        this.relations = [];
        this.takeValue = undefined;
        this.skipValue = undefined;
        return this;
    }

    public static orWhere<T extends typeof BaseEntity>(
        this: T,
        field: string,
        operator: '=' | '!=' | '<' | '>' | '<=' | '>=' | 'LIKE' = '=',
        value?: any
    ): T {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }

        let condition: FindOptionsWhere<any>;
        switch (operator) {
            case '=':
                condition = {[field]: Equal(value)};
                break;
            case '!=':
                condition = {[field]: Not(Equal(value))};
                break;
            case '<':
                condition = {[field]: LessThan(value)};
                break;
            case '<=':
                condition = {[field]: LessThanOrEqual(value)};
                break;
            case '>':
                condition = {[field]: MoreThan(value)};
                break;
            case '>=':
                condition = {[field]: MoreThanOrEqual(value)};
                break;
            case 'LIKE':
                condition = {[field]: Like(value)};
                break;
            default:
                throw new Error(`Unsupported operator ${operator}`);
        }

        this.orConditions.push(condition);
        return this;
    }

    public static where<T extends typeof BaseEntity>(
        this: T,
        field: string,
        operator: '=' | '!=' | '<' | '>' | '<=' | '>=' | 'LIKE',
        value: any
    ): T {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }

        let condition: FindOptionsWhere<any>;
        switch (operator) {
            case '=':
                condition = {[field]: Equal(value)};
                break;
            case '!=':
                condition = {[field]: Not(Equal(value))};
                break;
            case '<':
                condition = {[field]: LessThan(value)};
                break;
            case '<=':
                condition = {[field]: LessThanOrEqual(value)};
                break;
            case '>':
                condition = {[field]: MoreThan(value)};
                break;
            case '>=':
                condition = {[field]: MoreThanOrEqual(value)};
                break;
            case 'LIKE':
                condition = {[field]: Like(value)};
                break;
            default:
                throw new Error(`Unsupported operator ${operator}`);
        }

        this.conditions.push(condition);
        return this;
    }

    public static whereIn<T extends typeof BaseEntity>(
        this: T,
        field: string,
        values: any[]
    ): T {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }
        this.conditions.push({[field]: In(values)});
        return this;
    }

    public static orderBy<T extends typeof BaseEntity>(
        this: T,
        field: string,
        direction: 'ASC' | 'DESC' = 'ASC'
    ): T {
        this.orderOptions[field] = direction;
        return this;
    }

    public static limit<T extends typeof BaseEntity>(
        this: T,
        take: number
    ): T {
        this.takeValue = take;
        return this;
    }

    public static offset<T extends typeof BaseEntity>(
        this: T,
        skip: number
    ): T {
        this.skipValue = skip;
        return this;
    }

    public static with<T extends typeof BaseEntity>(
        this: T,
        relations: string[]
    ): T {
        this.relations = relations;
        return this;
    }

    public static async get<T extends typeof BaseEntity>(
        this: T
    ): Promise<InstanceType<T>[]> {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }

        const options = this.buildOptions();
        const results = await this.repository.find(options);
        this.reset();
        return results as InstanceType<T>[];
    }

    public static async first<T extends typeof BaseEntity>(
        this: T
    ): Promise<InstanceType<T> | null> {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }

        const options = this.buildOptions();
        const result = await this.repository.findOne(options);
        this.reset();
        return result as InstanceType<T> | null;
    }

    public static async modify<T extends typeof BaseEntity>(
        this: T,
        data: Partial<InstanceType<T>>
    ): Promise<InstanceType<T>> {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }

        const where = this.mergeConditions();
        await this.repository.update(where, data);
        this.reset();
        return await this.repository.findOne({where}) as unknown as InstanceType<T>;
    }

    public static async destroy<T extends typeof BaseEntity>(
        this: T, {softDelete = false}: { softDelete?: boolean } = {}
    ): Promise<number> {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }
        const where = this.mergeConditions();
        const result = softDelete ? await this.repository.softDelete(where) : await this.repository.delete(where);
        this.reset();
        return result.affected || 0;
    }

    private static buildOptions() {
        let whereOption: FindOptionsWhere<any> | FindOptionsWhere<any>[];
        const andGroup = this.mergeConditions();

        if (this.orConditions.length > 0) {
            const orGroup = this.orConditions;
            whereOption = [
                ...(Object.keys(andGroup).length ? [andGroup] : []),
                ...orGroup
            ];
        } else {
            whereOption = andGroup;
        }

        return {
            where: whereOption,
            order: this.orderOptions,
            relations: this.relations,
            take: this.takeValue,
            skip: this.skipValue,
        };
    }

    private static mergeConditions(): FindOptionsWhere<any> {
        if (this.conditions.length === 0) {
            return {};
        }
        if (this.conditions.length === 1) {
            return this.conditions[0];
        }
        return this.conditions.reduce((acc, condition) => {
            Object.assign(acc, condition);
            return acc;
        }, {} as FindOptionsWhere<any>);
    }

    public static async summing<T extends typeof BaseEntity>(
        this: T,
        field: string
    ): Promise<number> {
        if (!this.repository) {
            this.repository = AppDataSource.getRepository(this);
        }
        const where = this.mergeConditions();
        const result = await this.repository.createQueryBuilder()
            .select(`SUM(${field})`, 'sum')
            .where(where)
            .getRawOne();
        this.reset();
        return result?.sum || 0;
    }

    public static applyFilters<T extends typeof BaseEntity>(
        this: T,
        ...allowedFilters: string[]
    ): T {
        const filters = request().filters();

        if (filters) {
            Object.keys(filters).forEach(key => {
                if (allowedFilters.includes(key)) {
                    if (filters[key] instanceof Array) {
                        this.whereIn(key, filters[key]);
                    }
                    if (typeof filters[key] === 'string' || typeof filters[key] === 'number') {
                        this.where(key, '=', filters[key]);
                    }
                }
            });
        }
        return this;
    }

    /**
     * Applies pagination settings from the request context to the query.
     * This method sets the `take` and `skip` values based on the request's pagination parameters.
     * @template T - The type of the entity.
     * @param {number} [perPage=null] - The number of records per page.
     * @returns {T} The current entity class.
     */
    public static applyPagination<T extends typeof BaseEntity>(
        this: T,
        perPage?: number,
    ): T {
        this.takeValue = perPage ?? request().limit();
        this.skipValue = (request().page() - 1) * this.takeValue;
        return this;
    }

    private static reset() {
        this.conditions = [];
        this.orderOptions = {};
        this.relations = [];
        this.takeValue = undefined;
        this.skipValue = undefined;
    }
}
