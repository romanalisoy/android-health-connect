import {
    Column,
    CreateDateColumn,
    ObjectIdColumn,
    UpdateDateColumn
} from "typeorm";
import {ObjectId} from "mongodb";

export default abstract class BodyMeasurementBase {
    @ObjectIdColumn()
    _id!: ObjectId;

    @Column()
    id!: string;

    @Column({type: 'text'})
    dataOrigin!: string;

    @Column()
    time!: number;

    @CreateDateColumn()
    created_at: DateString;

    @UpdateDateColumn()
    updated_at: DateString;
}
