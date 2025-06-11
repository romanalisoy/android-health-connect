import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'Heights',
})
export default class Height extends BaseEntity implements IModel {
    @Column()
    inInches: number;

    @Column()
    inMiles: number;

    @Column()
    inFeet: number;

    @Column()
    inKilometers: number;

    @Column()
    inMeters: number;
}