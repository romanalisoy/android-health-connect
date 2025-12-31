import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";
import {SpeedSample} from "../../../../types/health";

@Entity({
    name: 'Speeds',
})
export default class Speed extends BaseEntity implements IModel {
    @Column()
    samples: SpeedSample[];
}
