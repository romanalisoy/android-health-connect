import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'Weights',
})
export default class Weight extends BaseEntity implements IModel {
    @Column()
    inPounds: number;

    @Column()
    inOunces: number;

    @Column()
    inMicrograms: number;

    @Column()
    inGrams: number;

    @Column()
    inMilligrams: number;

    @Column()
    inKilograms: number;
}