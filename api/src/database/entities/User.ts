import {
    BaseEntity,
    Column,
    CreateDateColumn,
    Entity,
    ObjectIdColumn,
    UpdateDateColumn
} from "typeorm";


@Entity({
    name: 'User',
})
export default class User extends BaseEntity implements IModel {
    @ObjectIdColumn()
    id!: string;

    @Column({type: 'text', unique: true})
    username: string;

    @Column({type: 'text'})
    password: string;

    @Column({type: 'text'})
    fmcToken: string;

    @CreateDateColumn()
    created_at: DateString;

    @UpdateDateColumn()
    updated_at: DateString;
}