import {
    Column,
    Entity,
    ObjectIdColumn,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'TotalCaloriesBurned',
})
export default class TotalCaloriesBurned extends BaseEntity implements IModel {
    @ObjectIdColumn()
    id!: string;

    @Column()
    energy: CaloriesBurnedEnergy;
}

export interface CaloriesBurnedEnergy {
    inKilocalories: number;
    inKilojoules: number;
    inJoules: number;
    inCalories: number;
}