import {
    BaseEntity,
    Column,
    CreateDateColumn,
    Entity,
    Index,
    PrimaryColumn,
    UpdateDateColumn
} from "typeorm";


@Entity({
    name: 'BodyStats',
})
@Index(['user_id', 'record_date'], {unique: true})
export default class BodyStats extends BaseEntity implements IModel {
    @Column()
    @PrimaryColumn()
    id!: string;

    @Column()
    user_id: string;

    @Column({type: 'text'})
    record_date: string; // yyyy-mm-dd format

    @Column({type: 'decimal', nullable: true})
    waist: number | null;

    @Column({type: 'decimal', nullable: true})
    neck: number | null;

    @Column({type: 'decimal', nullable: true})
    chest: number | null;

    @Column({type: 'decimal', nullable: true})
    right_arm: number | null;

    @Column({type: 'decimal', nullable: true})
    left_arm: number | null;

    @Column({type: 'decimal', nullable: true})
    right_forearm: number | null;

    @Column({type: 'decimal', nullable: true})
    left_forearm: number | null;

    @Column({type: 'decimal', nullable: true})
    right_shoulder: number | null;

    @Column({type: 'decimal', nullable: true})
    left_shoulder: number | null;

    @Column({type: 'decimal', nullable: true})
    hips: number | null;

    @Column({type: 'decimal', nullable: true})
    right_thigh: number | null;

    @Column({type: 'decimal', nullable: true})
    left_thigh: number | null;

    @Column({type: 'decimal', nullable: true})
    right_calve: number | null;

    @Column({type: 'decimal', nullable: true})
    left_calve: number | null;

    @CreateDateColumn()
    created_at: DateString;

    @UpdateDateColumn()
    updated_at: DateString;
}
