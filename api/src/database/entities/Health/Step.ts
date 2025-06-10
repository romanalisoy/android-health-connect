import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'Steps',
})
export default class Step extends BaseEntity implements IModel {
    @Column()
    count: number;
}
