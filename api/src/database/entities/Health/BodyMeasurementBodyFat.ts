import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_body_fat',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementBodyFat extends BodyMeasurementBase implements IModel {
    @Column()
    percentage!: number;
}
