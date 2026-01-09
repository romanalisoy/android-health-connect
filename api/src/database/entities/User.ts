import {
    BaseEntity,
    Column,
    CreateDateColumn,
    Entity,
    PrimaryColumn,
    UpdateDateColumn
} from "typeorm";


@Entity({
    name: 'User',
})
export default class User extends BaseEntity implements IModel {
    @Column()
    @PrimaryColumn()
    id!: string;

    @Column({type: 'text', unique: true})
    email: string;

    @Column({type: 'text'})
    password: string;

    @Column({type: 'text', nullable: true})
    fcmToken: string;

    @Column({type: 'text'})
    full_name: string;

    @Column({type: 'date', nullable: true})
    birthdate: Date | null;

    @Column({type: 'text', nullable: true})
    profile_picture: string | null;

    @CreateDateColumn()
    created_at: DateString;

    @UpdateDateColumn()
    updated_at: DateString;
}
