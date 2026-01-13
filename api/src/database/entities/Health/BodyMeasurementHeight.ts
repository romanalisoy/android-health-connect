import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_height',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementHeight extends BodyMeasurementBase implements IModel {
    @Column()
    height!: number;
}
