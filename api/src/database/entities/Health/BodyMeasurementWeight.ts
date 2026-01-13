import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_weight',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementWeight extends BodyMeasurementBase implements IModel {
    @Column()
    weight!: number;
}
