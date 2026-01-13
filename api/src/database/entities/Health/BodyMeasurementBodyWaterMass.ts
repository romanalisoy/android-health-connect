import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_body_water_mass',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementBodyWaterMass extends BodyMeasurementBase implements IModel {
    @Column()
    mass!: number;
}
