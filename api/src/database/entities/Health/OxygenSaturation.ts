import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'OxygenSaturation',
})
export default class OxygenSaturation extends BaseEntity implements IModel {
    @Column()
    percentage: number;
}
