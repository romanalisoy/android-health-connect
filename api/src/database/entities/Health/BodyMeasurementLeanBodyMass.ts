import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_lean_body_mass',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementLeanBodyMass extends BodyMeasurementBase implements IModel {
    @Column()
    mass!: number;
}
