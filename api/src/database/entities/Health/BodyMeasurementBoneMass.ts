import {Column, Entity, Index} from "typeorm";
import BodyMeasurementBase from "./BodyMeasurementBase";

@Entity({
    name: 'body_measurement_bone_mass',
})
@Index(['id'], {unique: true})
export default class BodyMeasurementBoneMass extends BodyMeasurementBase implements IModel {
    @Column()
    mass!: number;
}
