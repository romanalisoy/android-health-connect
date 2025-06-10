import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'Speeds',
})
export default class Speed extends BaseEntity implements IModel {
    @Column()
    samples: SpeedSample[];
}

export interface SpeedSample {
    speed: SpeedMeasurement;
    time: string;
}

export interface SpeedMeasurement {
    inMilesPerHour: number;
    inMetersPerSecond: number;
    inKilometersPerHour: number;
}