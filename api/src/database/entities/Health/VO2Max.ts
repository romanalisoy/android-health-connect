import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'Vo2Max',
})
export default class Vo2Max extends BaseEntity implements IModel {
    @Column()
    measurementMethod: number;

    @Column()
    vo2MillilitersPerMinuteKilogram: number;
}