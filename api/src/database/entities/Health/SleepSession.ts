import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";
import {SleepStage} from "../../../../types/health";

@Entity({
    name: 'SleepSessions',
})
export default class SleepSession extends BaseEntity implements IModel {
    @Column()
    stages: SleepStage[];

    @Column()
    notes: string | null;

    @Column()
    title: string | null;
}