import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'HeartRate',
})
export default class HeartRate extends BaseEntity implements IModel {
    @Column(type => HeartRateSample)
    samples: HeartRateSample[];
}

class HeartRateSample {
    @Column()
    beatsPerMinute: number;

    @Column()
    time: string;
}