import {
    Column,
    Entity,
    ObjectIdColumn,
} from "typeorm";
import BaseEntity from "../BaseEntity";
import {DECIMAL_PRECISION} from "../../../core/configs/defaults.config";

@Entity({
    name: 'Distances',
})
export default class Distance extends BaseEntity implements IModel {
    @ObjectIdColumn()
    id!: string;

    @Column('decimal', DECIMAL_PRECISION)
    inInches: number;

    @Column('decimal', DECIMAL_PRECISION)
    inMiles: number;

    @Column('decimal', DECIMAL_PRECISION)
    inFeet: number;

    @Column('decimal', DECIMAL_PRECISION)
    inKilometers: number

    @Column('decimal', DECIMAL_PRECISION)
    inMeters: number;
}