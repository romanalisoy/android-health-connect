import {
    Column,
    Entity,
    ObjectIdColumn,
} from "typeorm";
import BaseEntity from "../BaseEntity";
import {CaloriesBurnedEnergy} from "../../../../types/health";

@Entity({
    name: 'TotalCaloriesBurned',
})
export default class TotalCaloriesBurned extends BaseEntity implements IModel {
    @ObjectIdColumn()
    id!: string;

    @Column()
    energy: CaloriesBurnedEnergy;
}