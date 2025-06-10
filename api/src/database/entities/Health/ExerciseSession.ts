import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'ExerciseSessions',
})
export default class ExerciseSession extends BaseEntity implements IModel {
    @Column()
    exerciseRoute: object;

    @Column()
    exerciseType: number;

    @Column()
    title: string | null;

    @Column()
    segments: any[];

    @Column()
    notes: string | null;

    @Column()
    endZoneOffset: TimeZoneOffset;

    @Column()
    startZoneOffset: TimeZoneOffset;

    @Column()
    laps: any[];
}