import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'Hydration',
})
export default class Hydration extends BaseEntity implements IModel {
    @Column()
    inMilliliters: number;

    @Column()
    inFluidOuncesUs: number;

    @Column()
    inLiters: number;
}