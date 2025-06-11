import {
    Column,
    Entity,
} from "typeorm";
import BaseEntity from "../BaseEntity";

@Entity({
    name: 'BloodPressure',
})
export class BloodPressure extends BaseEntity implements IModel {
    @Column(type => Systolic)
    systolic: Systolic;

    @Column(type => Diastolic)
    diastolic: Diastolic;

    @Column()
    bodyPosition: number;

    @Column()
    measurementLocation: number;
}

class Systolic {
    @Column()
    inMillimetersOfMercury: number;
}

class Diastolic {
    @Column()
    inMillimetersOfMercury: number;
}