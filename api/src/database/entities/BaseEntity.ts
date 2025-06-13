import {BaseEntity as TypeORMEntity, Column, PrimaryGeneratedColumn} from 'typeorm';

export default class BaseEntity extends TypeORMEntity {
    @PrimaryGeneratedColumn('uuid')
    uuid!: string;

    @Column()
    app: string;

    @Column()
    start: string;

    @Column()
    end: string;
}
